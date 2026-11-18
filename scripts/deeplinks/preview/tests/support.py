"""inventaire.io's answers, and a client that replays them.

The entities were recorded from inventaire.io on 2026-11-18. Readers, lists, étagères, groups and
copies are invented, in the shape inventaire.io gives them: no real reader's data in the repository.
"""

import json
from pathlib import Path
from typing import Any

from app.inventaire import Unreachable

_FIXTURES: Path = Path(__file__).parent / "fixtures"

EDITION_ISBN: str = "isbn:9782070360024"
WORK_URI: str = "wd:Q163297"
AUTHOR_URI: str = "wd:Q34670"
ITEM_ID: str = "d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6"
LIST_ID: str = "e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
ELEMENT_ID: str = "f0e1d2c3b4a5968778695a4b3c2d1e0f"
SHELF_ID: str = "0a1b2c3d4e5f60718293a4b5c6d7e8f9"
LEA_ID: str = "a3f1c2d4e5b60718293a4b5c6d7e8f90"
REMI_ID: str = "b7e2d1c0f9a8b7c6d5e4f3a2b1c0d9e8"
SAM_ID: str = "c4d5e6f708192a3b4c5d6e7f8091a2b3"
GROUP_SLUG: str = "polar-et-noir"


def fixture(name: str) -> dict[str, Any]:
    return json.loads((_FIXTURES / f"{name}.json").read_text())


class RecordedInventaire:
    """Replays an answer per endpoint and first query value, `None` for anything else, as
    inventaire.io's 4xx; raises `Unreachable` throughout when `reachable` is false."""

    base_url: str = "https://inventaire.io"

    def __init__(self, reachable: bool = True) -> None:
        self.reachable: bool = reachable
        self.requests: list[tuple[str, dict[str, str]]] = []
        self.answers: dict[tuple[str, str], dict[str, Any]] = {
            ("entities/by-uris", EDITION_ISBN): fixture("entities_edition"),
            ("entities/by-uris", WORK_URI): fixture("entities_work"),
            ("entities/by-uris", AUTHOR_URI): fixture("entities_author"),
            ("items/by-ids", ITEM_ID): fixture("items_by_ids"),
            ("users/by-ids", LEA_ID): fixture("users_by_ids_lea"),
            ("users/by-ids", REMI_ID): fixture("users_by_ids_remi"),
            ("lists/by-ids", LIST_ID): fixture("lists_by_ids"),
            ("lists/by-element-id", ELEMENT_ID): fixture("lists_by_element_id"),
            ("shelves/by-ids", SHELF_ID): fixture("shelves_by_ids"),
            ("users/by-usernames", "Lea"): fixture("users_by_usernames_lea"),
            ("users/by-usernames", "remi"): fixture("users_by_usernames_remi"),
            ("users/by-usernames", "sam"): fixture("users_by_usernames_sam"),
            ("lists/by-creators", REMI_ID): fixture("lists_by_creators_remi"),
            ("lists/by-creators", SAM_ID): fixture("lists_by_creators_sam"),
            ("groups/by-slug", GROUP_SLUG): fixture("groups_by_slug"),
            ("groups/by-slug", "club-de-lecture"): fixture("groups_by_slug_no_description")
        }

    def get(self, endpoint: str, query: dict[str, str]) -> dict[str, Any] | None:
        self.requests.append((endpoint, query))
        if not self.reachable:
            raise Unreachable(endpoint)
        return self.answers.get((endpoint, next(iter(query.values()))))
