# Links to a copy or an étagère, on link.exlibris.lunabee.ovh

Shipped on 2026-11-16, iOS and Android (issue #142, PR #149, fourth task of the « Deep links » sprint, after
[0092](0092-entity-deep-links.md), [0093](0093-network-deep-links.md) and [0094](0094-list-deep-links.md)).
`https://link.exlibris.lunabee.ovh/items/<id>` opens a copy and `/shelves/<id>` an étagère, on the Inventaire tab;
without the app, or for an étagère outside my network, the link lands on the same page on inventaire.io. Android built
and unit-tested, never run on an emulator.

## What it does

- **Which links.** inventaire.io's own paths (`/items/:id`, `/shelves/:id`); ids whole-matched on `[0-9a-f]{32}`
  (checked on real items and étagères) before any request. Both open on Inventaire: one tab per kind of link.
- **A copy.**
  - In the store (mine, or a friend's) → the Fiche livre anchored on it, `BookAnchor.item`, « Emprunter à… » on a
    friend's when its status allows.
  - Not in the store (a stranger's public copy, or a friend's not synced yet) → `GET /api/items/by-ids` read without
    storing anything, then the Fiche livre of its edition. A stranger's copy never reaches the local search.
- **An étagère.**
  - In the store → `ShelfDetailView`.
  - Not in the store → `GET /api/shelves/by-ids`, its owner checked. Mine or a friend's: its books read first, then
    the étagère upserted and linked to the books already in the store, saved once; none of the friend's books is
    fetched (they arrive with their inventory sync). A failed read stores nothing.
  - Anyone else's → inventaire.io: opening it would put a stranger's copies in the store, which the local search and
    « Chez mes amis » read as mine and my friends'.
- **Unknown id, private (`401`), unknown (`404`), or no network** → inventaire.io's page in the browser.

## Technical surface

- **Server** — `scripts/deeplinks/apple-app-site-association` gains `/items/*` and `/shelves/*`.
- **iOS**
  - `DeepLink.item(id:)`, `DeepLink.shelf(id:)`.
  - `AppModels/Inventory/InventoryModel+DeepLink.swift`: `fetchEditionURI(ofItem:)`, stores nothing.
  - `AppModels/Shelf/ShelfModel+DeepLink.swift`: `fetchShelf(id:ownedByOneOf:)`. `ShelfModel.fetchItemIds(ofShelves:)`
    is the one `with-items` request, shared with the sync's `linkItems`.
  - `NavigationDestination.linkedItem(id:…)` / `linkedShelf(id:ownedByOneOf:…)`: static async, testable with
    `MockAPIService`. Owners are me and my friends. `ShelvesView` applies `.opensPendingLink(on: .inventory, path:)`.
- **Android** — `DeepLink.Item`, `DeepLink.Shelf`; `InventoryRepository.isStored`, `fetchEditionUri`;
  `ShelfRepository.isStored`, `fetchShelf(id, owners)`: membership fetched first, then `upsert` + `replaceItems` in one
  `db.withTransaction`.
- **Tests** — `DeepLinkTests`, `LinkedInventoryItemAndShelfTests`; Android `DeepLinkTest`.

## Pitfalls

- **`with-items` is deprecated** server-side, renamed `with-items-ids`; both answer `items: [ids]`. The app still sends
  the old name, through `?action=by-ids`, also deprecated.
- **`ShelfModel.swift` is pinned by its baseline** (`file_length` 578, `type_body_length` 345, matched on the counts):
  any edit there keeps the line count, or the build fails.

## Known limits

- A friend's étagère linked before their inventory sync shows fewer books until it runs.
- A friend's copy not yet synced opens its edition, not their copy.
