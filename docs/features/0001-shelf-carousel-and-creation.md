# The shelf carousel, and making a shelf from inside the app

Shipped on 2026-08-06 from PRD `docs/prd/0001-bookshelf-carousel-and-create.md` (deleted — git
history). See ADR `docs/adr/0003-bookshelf-inventory.md` for the read-only screen this builds on,
and ADR `docs/adr/0004-shelf-creation-write.md` for the write.

> Written on 2026-08-29, well after the fact, from the PRD and the code — the other feature
> documents were written as their features shipped, this one was not. Where the two disagreed the
> code won. Two parts of what shipped here have since been replaced; each is marked below.

## What it does

The étagères are a horizontal carousel of large cards instead of a cramped 2-up grid. One card
holds many books, the next card peeks at the screen edge so you can tell there are more, and each
swipe snaps a card into frame. Shelves are ordered A→Z. "Tous les livres" stays below the
carousel as a flat list of everything owned, and the page's own scroll stays vertical — adding
shelves no longer pushes the inventory off-screen.

A shelf can be made without leaving the app, which was previously only possible on
inventaire.io. It appears on the carousel the moment you submit, in its alphabetical place, while
the write happens behind it.

How the books are arranged on a plank depends on how many there are: one book stands face-on with
its real cover; books that all fit stand as spines with the last one leaning; books that overflow
fill the left half with spines and pile the rest flat on the right. Spine thickness follows the
book's real page count.

## Technical surface

- Screens touched: `Features/Shelves` — `ShelvesContent` (the carousel and the flat list),
  `ShelfRowView` (a card), `ShelfFormView` (the create sheet).
- New pure module: `ShelfBooksLayout` — the "mixte" layout maths lifted out of SwiftUI. Given
  page counts, a usable width and a zone height it returns a plan (`singleCover`, `allVertical`,
  or `mixed(verticalCount:)`) plus per-book geometry. `ShelfBooksView` is a renderer over it.
- New write: `ShelfModel.createShelf(name:description:visibility:ownerId:modelContext:)` — the
  first mutation in the shelf domain, on ADR 0001's `optimistic(_:apply:revert:request:)`. A
  placeholder `Shelf` with an `OptimisticID` is inserted and shown immediately; the request runs
  in a model-owned task; on success the placeholder is deleted and replaced by the server's
  canonical shelf; on failure it is deleted and the error surfaces through `AppErrorReporter`.
- The carousel is a horizontal `ScrollView` + `LazyHStack` with `scrollTargetLayout()` and
  `scrollTargetBehavior(.viewAligned)`; cards are ~86% of the screen width. Shelves come from
  `@Query(sort: \.name)`, so the new shelf sorts itself into place with no extra work.
- No SwiftData schema change beyond ADR 0003.
- Tests: `ShelfBooksLayoutTests` (28 cases — the boundaries, the split, the default thickness,
  the height cap, the pile fit-scaling) and `ShelfModelTests`.

## Notable decisions

- **The layout maths left SwiftUI so it could be tested.** It is pure and deterministic — the
  height variance is a seeded table, not `random()` — so the tests need no rendering and no
  network, which matters because this project's integration suite hits the real server and is
  excluded from CI.
- **Creation is optimistic, not blocking.** A shelf is cheap to make and cheap to undo, so the
  card appears at once and rolls back if the server refuses. This is the case that established
  the pattern for the shelf domain; everything written to a shelf since follows it.
- **New shelves default to private** (`visibility: []`). Publishing a shelf is a decision, not a
  default, and nothing in the app offers to change it yet.
- **Alphabetical, not recent-first.** A shelf you cannot find is worse than a shelf you cannot
  see first, and `@Query` sorting means the order survives every insert for free.

## What has since been replaced

- **The scrub.** Press-and-hold-then-slide to zoom through a shelf's books, released to open one,
  was the way to reach a book from a card. It was rebuilt on a UIKit recognizer the same week
  (`docs/features/0002-spine-strip-scrub-margin.md`), replaced by tap-to-select on 2026-08-18
  (`0003`, ADR 0005), and replaced again by press-and-hold with a focus overlay on 2026-08-19
  (`0004`, ADR 0006). What remains of the original is the gesture's problem statement, not its
  code: `ShelfPressGestureView` / `ShelfPressRecognizer` / `ShelfFocusModel` are the current
  answer.
- **The trailing create card.** Creation lived on an empty "+" card at the end of the carousel.
  On 2026-08-19 the button moved into the "Étagères" section header and the trailing card became
  the empty state (`docs/features/0005-shelf-label-and-add.md`), which later became an errand
  leading to the scanner (`ShelfEmptyStateErrand`). `ShelfFormView` itself is still the sheet, now
  reached from the header and doing double duty for editing.

The carousel, the layout module, the optimistic create and the A→Z order all still stand.

## Known gaps

- `createShelf` posts to `/api/shelves?action=create`. The `?action=` form is deprecated
  server-wide on inventaire.io; it still works, but this call is on borrowed time and should be
  moved to the current route when something else touches it.
- The PRD's out-of-scope list has been worked through since: renaming and deleting a shelf
  shipped with `0005`, membership with `0006`, and the scrub's index mapping was made moot by the
  gesture being replaced twice. Nothing from that list is still outstanding.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> The paths below are the ones they had then; issues have since moved under `docs/`.
> To read them: `git log --diff-filter=D --oneline -- issues/ docs/issues/` then
> `git show <commit>^:<path>`.

- `issues/0001-extract-shelfbookslayout.md` — the layout module and its unit tests
- `issues/0002-horizontal-carousel.md` — the snapping carousel
- `issues/0003-longpress-arm-scrub.md` — the scrub, armed by a long press (since replaced)
- `issues/0004-create-shelf.md` — the create card, the form and the optimistic write
