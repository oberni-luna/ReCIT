"""The paths of an Ex-libris link, read with the whole-match rules of the apps' `DeepLink`.

Each segment is percent-decoded before it is checked, and only a segment that wholly matches what
inventaire.io allows ever reaches one of its query strings.
"""

import re
import unicodedata
from dataclasses import dataclass
from urllib.parse import quote, unquote

_ENTITY_URI: re.Pattern[str] = re.compile(r"(?:isbn|wd|inv):[A-Za-z0-9-]+")
_COUCH_ID: re.Pattern[str] = re.compile(r"[0-9a-f]{32}")
_SLUG: re.Pattern[str] = re.compile(r"([^.]+)(?:\.[0-9]+)?")


@dataclass(frozen=True)
class Entity:
    """A book, a work or an author, by its inventaire.io uri: `isbn:…`, `wd:…`, `inv:…`."""

    uri: str

    @property
    def path(self) -> str:
        """The link's path, the same on link.exlibris.lunabee.ovh and on inventaire.io."""
        return f"/entity/{self.uri}"


@dataclass(frozen=True)
class InventoryItem:
    """A copy of a book, by its id."""

    id: str

    @property
    def path(self) -> str:
        """The link's path, the same on link.exlibris.lunabee.ovh and on inventaire.io."""
        return f"/items/{self.id}"


@dataclass(frozen=True)
class EntityList:
    """A list, or one of its elements when `element_id` names one."""

    id: str
    element_id: str | None = None

    @property
    def path(self) -> str:
        """The link's path, the same on link.exlibris.lunabee.ovh and on inventaire.io."""
        if self.element_id is None:
            return f"/lists/{self.id}"
        return f"/lists/{self.id}/element/{self.element_id}"


@dataclass(frozen=True)
class Shelf:
    """An étagère, by its id."""

    id: str

    @property
    def path(self) -> str:
        """The link's path, the same on link.exlibris.lunabee.ovh and on inventaire.io."""
        return f"/shelves/{self.id}"


@dataclass(frozen=True)
class User:
    """A reader, by their username, in whatever case it was typed."""

    username: str

    @property
    def path(self) -> str:
        """The link's path, the same on link.exlibris.lunabee.ovh and on inventaire.io."""
        return f"/users/{quote(self.username)}"


@dataclass(frozen=True)
class Group:
    """A group, by its slug."""

    slug: str

    @property
    def path(self) -> str:
        """The link's path, the same on link.exlibris.lunabee.ovh and on inventaire.io."""
        return f"/groups/{quote(self.slug)}"


Link = Entity | InventoryItem | EntityList | Shelf | User | Group


def parse(raw_path: str) -> Link | None:
    """Reads the link a request path names.

    Args:
        raw_path: The path as the client sent it, percent-encoded, with or without a query.

    Returns:
        The link, or `None` for a path the apps would not open either.
    """
    try:
        segments: list[str] = [
            unquote(segment, errors="strict")
            for segment in raw_path.partition("?")[0].split("/")
            if segment
        ]
    except UnicodeDecodeError:
        return None

    match segments:
        case ["entity", uri] if _ENTITY_URI.fullmatch(uri):
            return Entity(uri)
        case ["items", item_id] if _COUCH_ID.fullmatch(item_id):
            return InventoryItem(item_id)
        case ["lists", list_id] if _COUCH_ID.fullmatch(list_id):
            return EntityList(list_id)
        case ["lists", list_id, "element", element_id] if (
            _COUCH_ID.fullmatch(list_id) and _COUCH_ID.fullmatch(element_id)
        ):
            return EntityList(list_id, element_id)
        case ["shelves", shelf_id] if _COUCH_ID.fullmatch(shelf_id):
            return Shelf(shelf_id)
        case ["users", username] if _is_username(username):
            return User(username)
        case ["groups", slug] if _is_slug(slug):
            return Group(slug)
        case _:
            return None


def _is_username(segment: str) -> bool:
    """inventaire.io's `Username`: two to twenty letters, digits or `_`, in any script."""
    return 2 <= len(segment) <= 20 and all(
        _is_letter(character) or unicodedata.category(character).startswith("N") or character == "_"
        for character in segment
    )


def _is_slug(segment: str) -> bool:
    """What `slugify` leaves of a group's name — letters in any script, digits and `-` — then the
    `.1`, `.2`… inventaire.io appends when the slug is taken."""
    match: re.Match[str] | None = _SLUG.fullmatch(segment)
    return match is not None and all(
        _is_letter(character) or character in "0123456789-" for character in match[1]
    )


def _is_letter(character: str) -> bool:
    return unicodedata.category(character).startswith("L")
