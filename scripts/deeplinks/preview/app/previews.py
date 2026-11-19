"""The reads each kind of link needs from inventaire.io, then what its preview says."""

from typing import Any

from . import entities, tags
from .inventaire import Inventaire
from .paths import Entity, EntityList, Group, InventoryItem, Link, Shelf, User

_ENTITY_QUERY: dict[str, str] = {
    "relatives": "|".join((entities.WORK, *entities.AUTHORS, entities.PUBLISHER)),
    "attributes": "info|labels|descriptions|claims|image"
}


def read_preview(link: Link, inventaire: Inventaire) -> tags.Preview | None:
    """What the page of `link` says.

    Returns:
        `None` when inventaire.io has nothing it may show for the link: missing, private, empty.

    Raises:
        Unreachable: When inventaire.io did not answer one of the reads.
    """
    match link:
        case Entity(uri):
            return tags.of_entity(_entities(inventaire, uri), uri)
        case InventoryItem(item_id):
            return _item(inventaire, item_id)
        case EntityList(list_id, None):
            return _list(inventaire, list_id)
        case EntityList(list_id, element_id):
            return _list_element(inventaire, list_id, element_id)
        case Shelf(shelf_id):
            return _shelf(inventaire, shelf_id)
        case User(username):
            return _user(inventaire, username)
        case Group(slug):
            return _group(inventaire, slug)


def _entities(inventaire: Inventaire, uri: str) -> dict[str, Any]:
    return inventaire.get("entities/by-uris", {"uris": uri, **_ENTITY_QUERY}) or {}


def _item(inventaire: Inventaire, item_id: str) -> tags.Preview | None:
    payload: dict[str, Any] = inventaire.get("items/by-ids", {"ids": item_id}) or {}
    item: dict[str, Any] | None = next(
        (item for item in payload.get("items") or [] if item.get("_id") == item_id),
        None
    )
    if item is None or not _is_public(item):
        return None
    owner: str | None = _username(inventaire, item.get("owner"))
    return tags.of_item(item, owner) if owner else None


def _list(inventaire: Inventaire, list_id: str) -> tags.Preview | None:
    query: dict[str, str] = {"ids": list_id, "attributes": "total"}
    payload: dict[str, Any] = inventaire.get("lists/by-ids", query) or {}
    entity_list: dict[str, Any] | None = (payload.get("lists") or {}).get(list_id)
    if entity_list is None or not _is_public(entity_list):
        return None
    creator: str | None = _username(inventaire, entity_list.get("creator"))
    return tags.of_list(entity_list, creator) if creator else None


def _list_element(inventaire: Inventaire, list_id: str, element_id: str) -> tags.Preview | None:
    payload: dict[str, Any] = inventaire.get("lists/by-element-id", {"id": element_id}) or {}
    entity_list: dict[str, Any] = payload.get("list") or {}
    uri: str | None = (payload.get("element") or {}).get("uri")
    if entity_list.get("_id") != list_id or not _is_public(entity_list) or not uri:
        return None
    creator: str | None = _username(inventaire, entity_list.get("creator"))
    if creator is None:
        return None
    return tags.of_list_element(entity_list, creator, _entities(inventaire, uri), uri)


def _shelf(inventaire: Inventaire, shelf_id: str) -> tags.Preview | None:
    query: dict[str, str] = {"ids": shelf_id, "with-items-ids": "true"}
    payload: dict[str, Any] = inventaire.get("shelves/by-ids", query) or {}
    shelf: dict[str, Any] | None = (payload.get("shelves") or {}).get(shelf_id)
    if shelf is None or not _is_public(shelf):
        return None
    owner: str | None = _username(inventaire, shelf.get("owner"))
    return tags.of_shelf(shelf, owner) if owner else None


def _user(inventaire: Inventaire, username: str) -> tags.Preview | None:
    payload: dict[str, Any] = inventaire.get("users/by-usernames", {"usernames": username}) or {}
    user: dict[str, Any] | None = next(iter((payload.get("users") or {}).values()), None)
    if user is None:
        return None
    list_count: int | None = None if user.get("bio") else _list_count(inventaire, user.get("_id"))
    return tags.of_user(user, list_count=list_count)


def _list_count(inventaire: Inventaire, user_id: str | None) -> int | None:
    """How many lists a reader shows, read as the total of a one-list page: only for a reader
    without a bio, whose page shows the count instead."""
    if not user_id:
        return None
    payload: dict[str, Any] | None = inventaire.get("lists/by-creators", {"users": user_id, "limit": "1"})
    total: Any = (payload or {}).get("total")
    return total if isinstance(total, int) else None


def _group(inventaire: Inventaire, slug: str) -> tags.Preview | None:
    payload: dict[str, Any] = inventaire.get("groups/by-slug", {"slug": slug}) or {}
    group: dict[str, Any] | None = payload.get("group")
    return tags.of_group(group) if group else None


def _username(inventaire: Inventaire, user_id: str | None) -> str | None:
    if not user_id:
        return None
    payload: dict[str, Any] = inventaire.get("users/by-ids", {"ids": user_id}) or {}
    return ((payload.get("users") or {}).get(user_id) or {}).get("username")


def _is_public(document: dict[str, Any]) -> bool:
    """The gate is the anonymous read itself: inventaire.io answers no session with only what anyone
    may see, and its answers for items and étagères carry no `visibility` at all. This is a second
    guard for the documents that do carry one: without `public`, they are not shown."""
    visibility: list[str] | None = document.get("visibility")
    return visibility is None or "public" in visibility
