# Press-and-hold to pick a book, with a focus overlay

Shipped on 2026-08-19. See ADR `docs/adr/0006-shelf-press-selection-scrim.md`.

## What it does

Press a book on a shelf and it springs up under your finger, answering at once and arriving at
twice its size as the hold completes. Let go early and it settles back just as fast as it had
grown, so a quick tap reads as a nudge rather than a slow retreat; a swipe still scrolls the
carousel untouched.

Keep holding and, halfway through, the screen starts receding: blurred and washed out, nav bar
and tab bar included, but never past halfway, so the rest of the étagère stays readable
underneath. The book itself stays sharp above it all. A haptic tick lands as selection mode
arms, and the book's cell fades in just above it — the cover at its own proportions, then title
and author, all sitting on one bottom line — clear of the thumb resting on the shelf, on a
backdrop that fades in and out vertically so it never draws a line across the shelf.

From there, sliding anywhere moves the selection to the book nearest your finger, every other
scroll is frozen, and lifting opens that book. Slide off the shelf and selection mode unwinds
the same way it arrived, so lifting there does nothing; slide back on and it winds up again.

## Technical surface

- Screens touched: the shelves carousel cards (`Features/Shelves`) and `MainTabView`, which
  hosts the overlay so it can reach over the nav bar and the tab bar.
- **Gesture:** `ShelfPressRecognizer` (a `UIGestureRecognizer` subclass reporting touch-down,
  the mid-hold beat, the arm, moves and release) and `ShelfPressGestureView`, its SwiftUI
  bridge. The feature's only UIKit.
- **Overlay:** `ShelfFocusModel` (what the press is doing), `ShelfFocusOverlayView` (veil,
  redrawn book, cell) and `ShelfFocusBookCell` (the pared-down cell with its fading backdrop).
- **Shared with the shelf**, so the redrawn book matches the original: `ShelfCardMetrics` (every
  card size from its width), `ShelfDrawnBooks` (the capped, newest-first run), `ShelfBookTitle`,
  `ShelfCoverView` and `ShelfBookOrientation`.
- `ShelfBooksLayout` gains `bookFrame(at:)`, `coverFrame`, `tallestBookHeight` and
  `topOfTallestBook(grownBy:)`; `ShelfBooksView` no longer grows or hides anything.
- Fixed along the way: `PaintedBookView` kept the first cover strip it ever loaded — invisible
  on a shelf, wrong in the overlay where one view is reused for every book the finger crosses.
  Its strip is now keyed to the edition, and `SpineStripLoader` keeps a main-actor mirror of its
  cache so the swap paints in the same frame instead of flashing a placeholder.
- No SwiftData schema change.

## Notable decisions

- Everything is veiled and only the pressed book is brought back sharp above it. Cutting the
  shelf out of the veil was tried three ways and always showed its own edge; a blur kept inside
  the card cannot escape the carousel's clipping.
- The veil stops at half opacity, so the other books stay visible under the finger, and it
  starts halfway through the hold — any earlier and a single tap flashes it.
- The copy is drawn over the shelf's own book rather than replacing it, so it needs no fade of
  its own, and no placeholder ever flashes while a cover loads.
- The copy is mounted a frame before it is animated. Inserted in the same transaction as its
  animation, SwiftUI draws it at the target value — the book jumped straight to ×2 and no curve
  change could fix it.
- Nothing animates from one book to the next: the cover and title swap outright, because
  morphing one into another reads as a glitch while picking.
- The cell rests above the grown book on a line fixed per shelf — the height the tallest book
  reaches once grown — so it clears them all and never moves while the finger slides.
- The exit lasts as long as the press did (capped at the hold, floored at 0.12s), so entering
  and leaving stay symmetric.
- Opening a book drops the overlay outright instead of animating it away, so nothing lingers
  over the detail screen.
- An overlay at the tab host, not a `fullScreenCover` or a second window: presenting would
  cancel the tracked touch and kill the gesture mid-slide.

## Tuning

All the timing hangs off `ShelfPressRecognizer.holdDuration`; `focusProgress` decides where in
the hold the veil starts. The look is in `ShelfRowView` (`fullGrowth`, `bounce`, `minimumExit`,
`cellDuration`, `cellBounce`), `ShelfFocusOverlayView` (`veilStrength`, `wash`) and
`ShelfFocusBookCell` (`peakOpacity`, `coverWidth`).

## Tests

`ShelfBooksLayoutTests` (28) covers the frames, the centred standing run, taps past the run, the
mixed shelf's left/right split, per-bar pile hits, the pile's bottom alignment, the card metrics,
the book frames the overlay redraws from, the shared baseline that lets the cell hold still, and
the line the cell rests on. `SpineStripLoaderTests` (6) covers the crop, the quarter turn for
lying books, and the title-colour threshold.
