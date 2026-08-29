# Cover-strip spines, reliable scrub, shelf margin

Shipped on 2026-08-06 from PRD `docs/prd/0002-spine-strip-scrub-margin.md` (deleted — git history).

> The scrub described here was replaced on 2026-08-18 by tap-to-select — see
> `docs/features/0003-shelf-tap-selection.md` / ADR 0005. The cover-strip spines and the
> book margin still stand.

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

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> The paths below are the ones they had then; issues have since moved under `docs/`.
> To read them: `git log --diff-filter=D --oneline -- issues/ docs/issues/` then
> `git show <commit>^:<path>`.

- `issues/0005-shelf-books-margin.md` — 24pt horizontal margin around books
- `issues/0006-cover-strip-spines.md` — cover-strip spines replacing the shader
- `issues/0007-reliable-scrub-uikit.md` — reliable scrub via a UIKit recognizer
