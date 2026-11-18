"""Names, descriptions, claims and images read off inventaire.io entities.

A name is taken in French, else in English, else in the entity's original language.
"""

from typing import Any

EntityDocument = dict[str, Any]
"""An entity as `entities/by-uris` answers it: a work, an edition, a person, a publisher…"""

WORK: str = "wdt:P629"
PUBLISHER: str = "wdt:P123"
AUTHORS: tuple[str, ...] = ("wdt:P50", "wdt:P58", "wdt:P110", "wdt:P6338")
"""Author, scenarist, illustrator, colorist: the roles inventaire.io lists as a book's authors."""

BOOK_TYPES: frozenset[str] = frozenset({"work", "edition"})

_LANGUAGES: tuple[str, ...] = ("fr", "en")


def resolve(payload: dict[str, Any], uri: str) -> EntityDocument | None:
    """The entity `uri` names in an answer of `entities/by-uris`, through its redirects: an ISBN
    answers under the edition's own uri, a merged entity under the one it was merged into."""
    entities: dict[str, EntityDocument] = payload.get("entities") or {}
    redirects: dict[str, str] = payload.get("redirects") or {}
    return entities.get(redirects.get(uri, uri))


def label(entity: EntityDocument) -> str | None:
    """The entity's name, or an edition's title, in the first language it has of ours."""
    return _in_language(entity.get("labels"), entity.get("originalLang"))


def description(entity: EntityDocument) -> str | None:
    """The entity's one-line description, in the first language it has of ours."""
    return _in_language(entity.get("descriptions"), entity.get("originalLang"))


def image_url(entity: EntityDocument) -> str | None:
    """The entity's image as inventaire.io gives it: `/img/entities/<hash>` or an absolute URL."""
    image: Any = entity.get("image")
    return image.get("url") if isinstance(image, dict) else None


def claims(entity: EntityDocument, claim: str) -> list[Any]:
    """The values of one claim, e.g. `wdt:P50`, empty when the entity has none."""
    return (entity.get("claims") or {}).get(claim) or []


def related(payload: dict[str, Any], entity: EntityDocument, through: tuple[str, ...]) -> list[EntityDocument]:
    """The entities `entity` points at through the claims `through`, in order, once each, among
    those the answer carries."""
    uris: list[str] = [uri for claim in through for uri in claims(entity, claim)]
    found: list[EntityDocument | None] = [resolve(payload, uri) for uri in dict.fromkeys(uris)]
    return [relative for relative in found if relative is not None]


def _in_language(values: dict[str, str] | None, original_language: str | None) -> str | None:
    if not values:
        return None
    for language in (*_LANGUAGES, original_language, "fromclaims"):
        if language and values.get(language):
            return values[language]
    return next(iter(values.values()), None)
