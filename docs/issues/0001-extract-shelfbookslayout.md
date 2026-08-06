Title: Extract ShelfBooksLayout pure module + unit tests
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0001-bookshelf-carousel-and-create.md

## What to build

Extract the "mixte" shelf layout math out of the SwiftUI `ShelfBooksView` into a pure,
SwiftUI-free module `ShelfBooksLayout`. Given the ordered books' page counts and the
shelf's usable width + zone height, it returns a layout plan — `singleCover`,
`allVertical`, or `mixed(verticalCount:)` — plus derived per-book geometry (spine
thickness = pages ÷ 15 defaulting to 20 and clamped, seeded height variance, lean offset
= previousHeight · tan(θ), pile thickness and fit-scaling, 9/16 zone-height cap).
`ShelfBooksView` becomes a thin renderer over this plan — no visible change on screen.

## Acceptance criteria

- [ ] `ShelfBooksLayout` contains the fit/split/thickness/lean/pile math with no SwiftUI import.
- [ ] `ShelfBooksView` renders identically to today, driven by the layout plan.
- [ ] Unit tests cover: 0/1 book, exact-fit boundary, overflow split (`verticalCount`), default-20 thickness when pages absent, 9/16 height cap, pile fit-scaling.
- [ ] Tests are network-free and deterministic (seeded variance), runnable in CI.
- [ ] App builds; shelves look unchanged.

## Blocked by

None - can start immediately.
