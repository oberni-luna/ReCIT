"""Public objects inventaire.io shows right now, one per kind of Ex-libris link, for deploy.sh's
checks: an item, its owner, a list, one of its elements, an étagère, a group.

Prints one `kind<TAB>path` line per kind, the path empty when inventaire.io shows none of that
kind, or does not answer. No reader's name or id is kept in the repository this way.
"""

import json
from http.client import HTTPException
from typing import Any
from urllib.error import URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen

USER_AGENT: str = "Ex-libris deploy check (+https://link.exlibris.lunabee.ovh)"
FRANCE: str = "[-5,42,8,51]"


def read(endpoint: str, **query: object) -> dict[str, Any]:
    """One public read of inventaire.io's API, `{}` when it fails."""
    url: str = f"https://inventaire.io/api/{endpoint}?{urlencode(query)}"
    try:
        with urlopen(Request(url, headers={"User-Agent": USER_AGENT}), timeout=10) as response:
            payload: Any = json.load(response)
    except (URLError, HTTPException, OSError, ValueError):
        return {}
    return payload if isinstance(payload, dict) else {}


def _first(values: Any) -> dict[str, Any]:
    """The first of `values`, `{}` when there is none."""
    return next(iter(values or []), {})


def paths() -> dict[str, str | None]:
    """A path per kind, `None` for a kind inventaire.io shows none of."""
    recent: dict[str, Any] = read("items/recent-public", limit=20)
    item: dict[str, Any] = _first(recent.get("items"))
    usernames: dict[str, str] = {user["_id"]: user["username"] for user in recent.get("users") or []}
    owner: str | None = usernames.get(item.get("owner") or "")
    owners: str = "|".join(usernames)
    entity_list: dict[str, Any] = _first(read("lists/by-creators", users=owners, limit=1).get("lists"))
    list_id: str | None = entity_list.get("_id")
    elements: dict[str, Any] = read("lists/elements", list=list_id, limit=1) if list_id else {}
    element: dict[str, Any] = _first(elements.get("elements"))
    shelves: dict[str, Any] = read("shelves/by-owners", owners=owners, limit=1).get("shelves") or {}
    shelf_id: str | None = next(iter(shelves), None)
    groups: list[dict[str, Any]] = read("groups/search-by-position", bbox=FRANCE).get("groups") or []
    slug: str | None = next((group.get("slug") for group in groups if group.get("searchable")), None)
    return {
        "item": item.get("_id") and f"/items/{item['_id']}",
        "reader": owner and f"/users/{quote(owner)}",
        "list": list_id and f"/lists/{list_id}",
        "element": element.get("_id") and f"/lists/{list_id}/element/{element['_id']}",
        "shelf": shelf_id and f"/shelves/{shelf_id}",
        "group": slug and f"/groups/{quote(slug)}"
    }


if __name__ == "__main__":
    for kind, path in paths().items():
        print(f"{kind}\t{path or ''}")
