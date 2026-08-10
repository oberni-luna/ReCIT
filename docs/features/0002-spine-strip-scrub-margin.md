# Cover-strip spines, reliable scrub, shelf margin

Shipped on 2026-08-06 from PRD `prd/0002-spine-strip-scrub-margin.md`.

## What it does

On the bookshelf, each spine is now built from the book's own cover (the leftmost sliver,
stretched), with the title in black or white for legibility and a shadow — so a shelf looks
like the real books. Books are inset from the card edges so they sit on the plank instead of
floating. Press-and-hold then slide on a shelf reliably scrubs through the books (zoom +
haptic) and opens the one under the finger, while a plain swipe still scrolls the carousel.

## Technical surface

- Screens touched: the shelves carousel cards (`Features/Shelves`).
- New: `SpineStripLoader` (cover crop + luminance → title colour, in-memory cache),
  `ScrubMapping` (pure x→index), `ScrubGestureView` (UIKit long-press bridge).
- `PaintedBookView` rebuilt to draw a stretched cover strip (no shader). `ShelfBooksView`
  applies a 24pt horizontal book margin. `ShelfRowView` drives the scrub from the UIKit
  overlay and disables the carousel scroll while scrubbing.
- Removed: `Watercolor.metal` and the Metal `.colorEffect`.
- No SwiftData schema change (`Edition.dominantColorHex` is now unused for spines).

## Notable decisions

- The scrub uses a single, deliberate UIKit gesture recognizer — SwiftUI can't compose
  hold-then-drag inside a snapping scroll view (two prior attempts blocked the scroll or
  dropped the touch). It recognises simultaneously with the scroll; a swipe still scrolls.
- Scrub index mapping stays linear over the books width (mixed spines+pile refinement is a
  follow-up).
- Strips are memory-cached only, keyed by edition; recomputed on a cold start from the
  Nuke-cached cover — no persistence, no extra network beyond loading the cover once.

## Issues

- `issues/0005-shelf-books-margin.md` — 24pt horizontal margin around books
- `issues/0006-cover-strip-spines.md` — cover-strip spines replacing the shader
- `issues/0007-reliable-scrub-uikit.md` — reliable scrub via a UIKit recognizer
