"""What a link's preview says — title, description, cover — from inventaire.io's answers, in French.

Every builder here is pure: the reads live in `previews`.
"""

import re
import unicodedata
from dataclasses import dataclass
from typing import Any

from . import entities

NARROW_NO_BREAK_SPACE: str = " "
NO_BREAK_SPACE: str = " "
SITE_NAME: str = "Ex-libris"

_DESCRIPTION_LENGTH: int = 200
_VOWELS: frozenset[str] = frozenset("aeiou")
_SPACE_BEFORE_PUNCTUATION: re.Pattern[str] = re.compile(r"[   ]+([?!:;])")
_BREAKING_WHITESPACE: re.Pattern[str] = re.compile(r"[^\S\u00a0\u202f]+")
_LIST_ELEMENTS: dict[str, tuple[str, str]] = {
    "work": ("œuvre", "œuvres"),
    "human": ("auteur·ice", "auteur·ices"),
    "publisher": ("maison d'édition", "maisons d'édition")
}


@dataclass(frozen=True)
class Preview:
    """The title and description of a link's page, and the cover its image is made of, if any."""

    title: str
    description: str
    cover_url: str | None = None


GENERIC: Preview = Preview(SITE_NAME, "Vos livres, et ceux qui circulent")
"""What a link says when it names nothing that may be shown: private, missing, unreadable."""


@dataclass(frozen=True)
class _Book:
    title: str
    byline: list[str]
    cover_url: str | None


def of_entity(payload: dict[str, Any], uri: str) -> Preview | None:
    """A book (a work or an edition) with its cover, or any other entity — an author, a publisher —
    by its name and description.

    Args:
        payload: The answer of `entities/by-uris` for `uri`, with its works, authors and publisher.
        uri: The uri the link names.
    """
    found: entities.EntityDocument | None = entities.resolve(payload, uri)
    if found is None:
        return None
    if book := _book(payload, found):
        byline: str = " · ".join(book.byline)
        description: str = f"{byline}, sur {SITE_NAME}" if byline else f"Sur {SITE_NAME}"
        return _preview(book.title, description, book.cover_url)
    if name := entities.label(found):
        about: str = entities.description(found) or GENERIC.description
        return _preview(f"{name} sur {SITE_NAME}", about)
    return None


def of_item(item: dict[str, Any], owner: str) -> Preview | None:
    """A copy of a book, from the snapshot inventaire.io keeps of its edition."""
    snapshot: dict[str, Any] = item.get("snapshot") or {}
    title: str | None = snapshot.get("entity:title")
    if not title:
        return None
    authors: str | None = snapshot.get("entity:authors")
    whose: str = f"{authors} · chez {owner}" if authors else f"Chez {owner}"
    return _preview(title, f"{whose}, sur {SITE_NAME}", snapshot.get("entity:image"))


def of_list_element(
    entity_list: dict[str, Any],
    creator: str,
    payload: dict[str, Any],
    uri: str
) -> Preview | None:
    """One element of a list: its title, and its cover when it is a book, said to be in the list."""
    found: entities.EntityDocument | None = entities.resolve(payload, uri)
    if found is None:
        return None
    book: _Book | None = _book(payload, found)
    title: str | None = book.title if book else entities.label(found)
    if title is None:
        return None
    list_name: str = _in_guillemets(entity_list.get("name") or "")
    description: str = f"Dans la liste {list_name} {_of(creator)}, sur {SITE_NAME}"
    return _preview(title, description, book.cover_url if book else None)


def of_list(entity_list: dict[str, Any], creator: str) -> Preview | None:
    """A list: its name, whose it is and how many works, authors or publishers it holds."""
    name: str | None = entity_list.get("name")
    if not name:
        return None
    nouns: tuple[str, str] | None = _LIST_ELEMENTS.get(entity_list.get("type") or "")
    count: int = entity_list.get("totalElements") or 0
    description: str = f"Une liste {_of(creator)} sur {SITE_NAME}"
    if nouns and count:
        description += f" · {_count(count, *nouns)}"
    return _preview(name, description)


def of_shelf(shelf: dict[str, Any], owner: str) -> Preview | None:
    """An étagère: its name, whose it is and how many of its books may be shown."""
    name: str | None = shelf.get("name")
    if not name:
        return None
    count: int = len(shelf.get("items") or [])
    description: str = f"Une étagère {_of(owner)} sur {SITE_NAME}"
    if count:
        description += f" · {_count(count, 'livre', 'livres')}"
    return _preview(name, description)


def of_user(user: dict[str, Any], list_count: int | None) -> Preview | None:
    """A reader: their bio, else how many books and lists they show.

    Args:
        user: The reader as `users/by-usernames` answers it.
        list_count: How many lists they show, `None` when it could not be read.
    """
    username: str | None = user.get("username")
    if not username:
        return None
    public: dict[str, Any] = (user.get("snapshot") or {}).get("public") or {}
    counts: list[str] = [
        _count(count, singular, plural)
        for count, singular, plural in (
            (public.get("items:count") or 0, "livre", "livres"),
            (list_count or 0, "liste", "listes")
        )
        if count
    ]
    description: str = user.get("bio") or " · ".join(counts) or GENERIC.description
    return _preview(f"{username} sur {SITE_NAME}", description)


def of_group(group: dict[str, Any]) -> Preview | None:
    """A group: its description, else how many members it has, admins included."""
    name: str | None = group.get("name")
    if not name:
        return None
    count: int = len(group.get("admins") or []) + len(group.get("members") or [])
    description: str = group.get("description") or _count(count, "membre", "membres")
    return _preview(f"{name} sur {SITE_NAME}", description)


def _book(payload: dict[str, Any], entity: entities.EntityDocument) -> _Book | None:
    """A work or an edition: its title, its authors then publisher, its cover."""
    if entity.get("type") not in entities.BOOK_TYPES:
        return None
    title: str | None = entities.label(entity)
    if title is None:
        return None
    works: list[entities.EntityDocument] = entities.related(payload, entity, (entities.WORK,))
    authors: list[str] = [
        name
        for work in (entity, *works)
        for name in map(entities.label, entities.related(payload, work, entities.AUTHORS))
        if name
    ]
    publisher: str | None = next(
        filter(None, map(entities.label, entities.related(payload, entity, (entities.PUBLISHER,)))),
        None
    )
    byline: list[str] = [part for part in (", ".join(dict.fromkeys(authors)), publisher) if part]
    work_titles: list[str] = [name for name in map(entities.label, works) if name]
    return _Book(_better_cased(title, work_titles), byline, entities.image_url(entity))


def _better_cased(title: str, work_titles: list[str]) -> str:
    """The work's title when it is the edition's in other capitals: catalogues often lower-case
    an edition's title (« L'étranger ») where the work keeps its own (« L'Étranger »)."""
    folded: str = title.casefold()
    return next((work_title for work_title in work_titles if work_title.casefold() == folded), title)


def _preview(title: str, description: str, cover_url: str | None = None) -> Preview:
    return Preview(_typeset(title), _shorten(_typeset(description)), cover_url or None)


def _typeset(text: str) -> str:
    """One line, and a narrow no-break space before `? ! : ;` where the text had a space."""
    one_line: str = _BREAKING_WHITESPACE.sub(" ", text).strip()
    return _SPACE_BEFORE_PUNCTUATION.sub(f"{NARROW_NO_BREAK_SPACE}\\1", one_line)


def _shorten(text: str) -> str:
    if len(text) <= _DESCRIPTION_LENGTH:
        return text
    cut: str = text[: _DESCRIPTION_LENGTH - 1]
    return f"{cut.rsplit(' ', 1)[0] if ' ' in cut else cut}…"


def _count(count: int, singular: str, plural: str) -> str:
    number: str = f"{count:,}".replace(",", NARROW_NO_BREAK_SPACE)
    return f"{number}{NO_BREAK_SPACE}{singular if count < 2 else plural}"


def _of(name: str) -> str:
    """« de Léa », « d'Inès »: French elides `de` before a vowel."""
    first: str = unicodedata.normalize("NFD", name[:1]).casefold()[:1]
    return f"d'{name}" if first in _VOWELS else f"de {name}"


def _in_guillemets(text: str) -> str:
    return f"«{NARROW_NO_BREAK_SPACE}{text}{NARROW_NO_BREAK_SPACE}»"
