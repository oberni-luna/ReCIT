## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

The new sorting surface, end to end, with no drag yet: the library laid out as it will be
filed, and every existing action still working. This is the slice that replaces the list.

**The scrolling region.** A three-column `LazyVGrid` of étagère cards. Each card draws a
fanned pile of up to five covers, the étagère's name, and its book count in the same text.
Cards are ordered as the projection gives them — server étagères A→Z, then drafts in creation
order.

**The anchored region.** A panel in the safe area that never scrolls: the « Livres à ranger ·
n » header, a one-row horizontal carousel of the books on no étagère with the next card
peeking, a variable-height text slot, and the action bar. The recap, « Appliquer », the
discard button and the proposal button are the existing ones, rewired — their behaviour is
other slices' business.

**Three pure modules come out of the views**, because a visual rewrite breaks silently in
exactly these two places (the wrong book grabbed, a card too wide for a small phone):

- `SortGridMetrics` — étagère column `(width − 4×16)/3`, book column
  `(width − 16 − 3×12 − 40)/3`, card height 158, cover ratio 2:3, carousel height, from a
  container width.
- `SortPile` — a section's card content: up to five covers with rank, depth and tilt, and
  which one is the draggable top.
- `DeterministicTilt` — extracted from `ShelfLabelTilt`, amplitude a parameter: ±1° for paper
  labels, ±10° for covers. Same djb2-over-Unicode-scalars plus splitmix64 finalizer, never
  `String.hashValue`.

**The order inside a section becomes a derivation.** `displayOrder` is deleted whole — the
property, `moveBook`'s `order:` parameter, `SortProjection`'s parameter, and every reset in
`land()`, `discardChanges()` and `freeze()`. In its place: books the session moved into a
section come first, most recent move first, then snapshot order. The top of a pile is
therefore the book most recently filed there.

**Two views move out of the shelves feature** because they now serve two features:
`ShelfSectionHeader` to `Features/Components/`, and `ShelfCoverView` likewise, refactored to
take `(url, title, size)` rather than an `InventoryItem` — this screen holds value types
only. Its rounded corner, parchment placeholder and shadow (`black 22 %`, radius 3, x 1,
y 2) are unchanged, and the shadow is kept in dark mode.

**Covers reserve a 2:3 frame before their image exists**, so a pile does not re-lay itself out
five times while the grid scrolls.

**States.** The opening sync shows a progress indicator in place of the grid, with the panel
present, inert, and its carousel height reserved so nothing jumps when data lands. An empty
carousel keeps the panel, with a « tout est rangé » line and the panel shrunk by the
carousel's height.

**Demolition, in the same slice**, because a half-replaced surface has two screens' worth of
code and neither works: `ManualSortListView`, `Model/Sorting/ManualSortRows` and its test
suite, `ManualSortCard`, `ManualSortEmptySectionRow`, `ManualSortSectionHeader`.

**Read the projection once.** The root view reads `sortSession.projection` a single time per
body and passes value types down; no card touches the model. A card reading it in its own
body pays a walk over the whole library per card per animation frame.

## Acceptance criteria

- [ ] The sorting screen shows every étagère as a card on a three-column grid, with a pile of
      up to five tilted covers, its name and its count.
- [ ] An étagère with one book shows that cover alone; one with none shows an empty frame of
      the same size.
- [ ] A given étagère's covers lean the same way on every launch, and accented French titles
      do not all lean alike.
- [ ] The books on no étagère appear in a one-row horizontal carousel inside a panel that
      does not scroll away, with the next card peeking.
- [ ] Column widths, gutters, peek and card heights are derived from the container width and
      hold at 320 / 375 / 393 / 430 pt.
- [ ] The recap, « Appliquer », the discard control and the proposal button work exactly as
      before this slice.
- [ ] The top book of a section is the one most recently filed there; books nobody moved keep
      inventory order behind them.
- [ ] `displayOrder` no longer exists anywhere in the project.
- [ ] The opening sync shows a progress indicator without the panel changing height when the
      library lands.
- [ ] An empty carousel leaves the panel in place with a « tout est rangé » line.
- [ ] `ShelfSectionHeader` and `ShelfCoverView` live in `Features/Components/`, the latter
      driven by values, and the inventory shelves still render identically.
- [ ] The list-era views and `ManualSortRows` are deleted, and the project builds with no
      reference to them.
- [ ] `SortGridMetrics`, `SortPile` and `DeterministicTilt` are pure — no SwiftUI, no store —
      and covered by Swift Testing suites, including "the draggable book is the first of the
      section".
- [ ] `SortProjectionTests` covers arrival order; `SortWritePlanTests`,
      `SortApplyLandingTests` and the ledger suites pass untouched.

## Blocked by

- `issues/0045-figma-frames-for-the-grid-surface.md`
