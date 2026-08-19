# Tap-to-select shelves, spines for lying books

Shipped on 2026-08-18. See ADR `docs/adr/0005-shelf-tap-selection.md`.

> The tapping described here was replaced the same day by press-and-hold selection — see
> `docs/features/0004-shelf-press-selection.md` / ADR 0006. The geometric hit testing and the
> quarter-turned covers for lying books still stand.

## What it does

On the bookshelf, a tap on a shelf grows the book nearest your finger and drops the previous
one back into place; tapping that grown book again opens it. Only one book stands out across
the whole carousel, and it drops back as soon as you swipe or tap anywhere off an étagère. The press-and-hold scrub is gone, and the shelf's list is now reached by
tapping the shelf's name. Books lying flat in a pile are painted with their cover turned a
quarter turn, so they read as spines seen side-on instead of horizontal bands.

## Technical surface

- Screens touched: the shelves carousel cards (`Features/Shelves`).
- New: `ShelfBookSelection` (shelfId + index, held once in `ShelvesContent`),
  `PaintedBookView.Orientation`, `SpineStripLoader.turnedQuarter(_:)` +
  `Strip.lyingImage`, and `ShelfBooksLayout.spineFrame(at:)` / `pileBarFrame(at:)` /
  `nearestIndex(to:)`.
- Removed: `ScrubGestureView` (the UIKit long-press bridge), `ScrubMapping` and its tests,
  the `scrubbing` binding and the carousel's `scrollDisabled`. No UIKit left in the feature.
- `ShelfRowView` now builds the layout and passes it to `ShelfBooksView`, so hit testing and
  rendering share one source of geometry.
- No SwiftData schema change.

## Notable decisions

- The second tap tests "is the nearest book the selected one", not "did the tap land inside
  the enlarged frame" — a tap slightly off a grown spine opens it instead of selecting a
  neighbour.
- The whole card is a tap target, plank included: a tap outside the books clamps to the
  nearest one rather than doing nothing.
- The quarter turn redraws pixels through a `CGContext` rather than setting a `UIImage`
  orientation, so there is no ambiguity about which way the sliver ends up.
- The shelf list lost the body tap and lives on the shelf name — an accepted regression in
  reach, taken to free the card for book selection.

## Tests

`ShelfBooksLayoutTests` covers the frames, the centred standing run, taps past the run, the
mixed shelf's left/right split, per-bar pile hits and the pile's bottom alignment;
`SpineStripLoaderTests` covers the quarter turn's swapped dimensions.
