# Inventaire et étagères

The first tab: my books, drawn on étagères in a carousel, plus « Tous les livres ». An étagère is an inventaire.io shelf; the layout maths is a pure module, selection is a press-and-hold.

## Code

- `Features/Shelves/` — `ShelvesView`, `ShelvesContent`
- `Features/Inventory/` — `InventoryCell`
- `Model/UserData/Shelf.swift`, `InventoryItem.swift`

## Decisions

- [ADR 0003](adr/0003-bookshelf-inventory.md)
- [ADR 0004](adr/0004-shelf-creation-write.md)
- [ADR 0005](adr/0005-shelf-tap-selection.md)
- [ADR 0006](adr/0006-shelf-press-selection-scrim.md)

## Features

- [0001 The shelf carousel, and making a shelf from inside the app](features/0001-shelf-carousel-and-creation.md) — étagères as a snapping horizontal carousel, a shelf created optimistically from the app, the layout maths lifted into a testable module
- [0002 Cover-strip spines, reliable scrub, shelf margin](features/0002-spine-strip-scrub-margin.md) — spines from cover art, UIKit scrub, 24pt book margin
- [0003 Tap-to-select shelves, spines for lying books](features/0003-shelf-tap-selection.md) — tap grows the nearest book, tap again opens it; quarter-turned cover for pile books (supersedes the scrub in 0002)
- [0004 Press-and-hold book selection with a focus overlay](features/0004-shelf-press-selection.md) — press grows a book ×2, the screen recedes behind a half-strength veil, the book's cell fades in above it, slide picks, release opens (supersedes the tapping in 0003)
- [0005 Paper labels, header add button, edit in the detail screen](features/0005-shelf-label-and-add.md) — the shelf name becomes a tilted paper tag, "Ajouter" moves to the section header, editing moves to the étagère's navigation bar (supersedes the card-level pencil in 0003)
- [0006 Adding and removing books from étagères](features/0006-shelf-membership.md) — file a book from its "..." menu, swipe it off the shelf you're looking at
- [0021 The empty shelf says what the first step is](features/0021-empty-shelf-first-steps.md) — a sentence above the plank, and one paper tag per way in: scan, search, or sort
- [0027 How far a first sync has got](features/0027-first-sync-progress.md) — a determinate bar over items received / announced for my inventory, each friend's cell and their profile; friends show before their books, which sync last, one by one
- [0036 Authors on every row, one gap under a group's header, a press that locks before it ends](features/0036-inventory-authors-group-gap-press-lock.md) — snapshot names fill editions first met as entities, with the works' authors as fallback; the group screen's empty actions section dropped and its gaps set to `medium`; selection arms halfway through the hold, same total length
- [0069 A book of « Tous les livres » lifts as a card on a long press](features/0069-inventory-row-long-press-card.md) — the inventory's `LazyVStack` row gave its context menu no margins and no ground, a `List` cell does; `InventoryCell.standsAlone` pads it, lays `backgroundDefault` under it and cuts the preview at 12 pt; built, not seen running, e2e not run
- [0078 A book row names three authors at most](features/0078-book-row-names-three-authors.md) — past three names, `InventoryCell` shows the first three then « et N autres » (`AuthorNamesSummary`); no `lineLimit`; iOS only
