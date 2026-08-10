# PRD — Cover-strip spines, reliable scrub, shelf margin

Status: needs-triage
Area: Inventory / Étagères (see ADR 0003 / 0004)

## Problem Statement

On a real inventory, three things feel off on the bookshelf. The painted (Metal-shader)
spines are attractive but generic — they don't look like the actual book. The books run
edge-to-edge on the plank, so the outermost ones look like they float in the void. And the
"press-and-slide to pick a book" scrub doesn't work: inside the horizontal carousel the
gesture either blocks the scroll or never tracks the finger.

## Solution

Make each spine look like the real book by building it from the book's own cover: take the
leftmost sliver of the cover and stretch it into the spine, write the title over it in
black or white depending on the strip's brightness, with a shadow. Inset the books from
the card edges so they sit on the plank instead of floating. And make the scrub reliably
work alongside the carousel scroll by driving it from a UIKit long-press recognizer.

## User Stories

1. As a RECITs collector, I want each spine built from my book's actual cover, so that my
   shelf looks like my real books, not generic painted blocks.
2. As a collector, I want the spine to use the leftmost ~10px of the cover, stretched, so
   that it reads as the book's edge/spine colours.
3. As a collector, I want the title written over the spine in black or white depending on
   the strip's brightness, so that it's always legible.
4. As a collector, I want the title to have a shadow, so that it stays readable over busy
   or mid-tone strips.
5. As a collector, I want lying books in a pile to use the same cover-strip treatment, so
   that spines and piles look consistent.
6. As a collector, I want a shelf with a single book to still show its full cover face-on,
   so that a lone book stays a highlight (unchanged).
7. As a collector whose cover hasn't loaded (or has none), I want a neutral parchment
   placeholder spine with the title, so that the shelf still renders cleanly.
8. As a collector, I want the strip to be computed once and cached, so that scrolling the
   shelf stays smooth and covers aren't re-processed constantly.
9. As a collector, I want the strip built from the already-cached cover image, so that no
   extra network cost is paid beyond loading the cover once.
10. As a collector, I want the spine colours to appear as the covers finish loading, so
    that the shelf fills in progressively without blocking.
11. As a collector, I want the Metal watercolour shader removed, so that the rendering is
    simpler and predictable (the painterly look is replaced by the real cover strip).
12. As a collector, I want ~24pt of horizontal margin around the books on each shelf, so
    that the outermost books don't look like they float off the plank edges.
13. As a collector, I want the plank to stay full-width while only the books are inset, so
    that the shelf still looks like a full shelf.
14. As a collector, I want the "does it all fit / split into a pile" decision to account
    for the margin, so that books never overflow into the inset area.
15. As a collector, I want to press and hold ~0.2s on a shelf then slide, and have the
    books highlight (zoom) under my finger with a haptic tick, so that I can pick a book
    by touch.
16. As a collector, I want a plain horizontal swipe to still scroll the carousel, so that
    the scrub never steals normal scrolling.
17. As a collector, I want the carousel scroll to freeze once a scrub is armed, so that
    the cards don't drift while I'm selecting.
18. As a collector, I want releasing a scrub on a book to open that book, so that I reach
    it in one gesture.
19. As a collector, I want sliding off the shelf during a scrub to cancel, doing nothing
    on release, so that I can bail out.
20. As a collector, I want a tap (no hold) to still open the shelf's list, so that the tap
    behaviour is unchanged.
21. As a collector, I want the scrub to work the same on every shelf card in the carousel,
    so that the interaction is consistent.

## Implementation Decisions

- **Cover-strip spine rendering replaces the Metal shader.** `Watercolor.metal` and the
  `.colorEffect` usage are removed. The painted-book view is rebuilt to draw a stretched
  cover strip via a resizable `Image`, with the title overlaid and shadowed.
- **New `SpineStripLoader`** (deep module) — given an edition's cover URL, it loads the
  cover through the existing cached image pipeline, crops the leftmost ~10px column, and
  returns a small strip image plus the title colour (black/white) chosen from the strip's
  average luminance. Results are held in an in-memory cache keyed by edition, recomputed on
  a cold start. No SwiftData schema change (nothing new persisted).
- **Strip geometry & luminance are pure.** The crop rectangle (leftmost N px, full height)
  and the luminance→title-colour decision are pure functions, separated from the image IO
  so they can be unit-tested.
- **Applies to standing spines and lying pile books.** The single-book "cover face-on"
  case is unchanged. When no strip is available yet, a parchment placeholder with the title
  is shown.
- **Shelf margin.** Books are inset 24pt on each side from the card edge; the usable book
  width becomes the card width minus 48pt, and the layout's fit/split decision uses that
  reduced width. The plank image stays full-width; only the books zone is inset.
- **Scrub driven by a UIKit long-press recognizer.** A `UILongPressGestureRecognizer`
  (min duration ~0.2s) is bridged into SwiftUI as an overlay on the books zone. It
  recognises simultaneously with the carousel's scroll so a quick swipe still scrolls; on
  `.began` it arms (disabling the carousel scroll and firing a haptic), on `.changed` it
  maps the finger's x to a book, and on `.ended` it opens the selected book or cancels.
  This is a deliberate, localised UIKit exception (SwiftUI gesture composition can't do
  hold-then-drag inside a snapping scroll view reliably — two prior attempts failed).
- **Scrub index mapping is pure.** The `location.x` + books-width + count → index (and the
  in-bounds test) is a pure function, extracted from the recognizer bridge so it can be
  unit-tested without UIKit. Mapping stays linear over the books width (the mixed-layout
  refinement remains a follow-up).
- **`ShelfBooksLayout` is unchanged internally**; it simply receives the reduced (margined)
  width from its caller.

## Testing Decisions

- **Good tests** assert observable output of a module's public interface, not internals;
  pure and deterministic, no UIKit/SwiftUI rendering, no network.
- **Scrub index mapping** (unit): given widths, counts and x positions, assert the selected
  index and the in-bounds result — left/right edges, out-of-bounds (above/below/beside the
  books), single book, clamping at the last book.
- **Luminance → title colour + crop geometry** (unit): assert black is chosen for a bright
  strip and white for a dark one (at/around the threshold), and that the crop rectangle is
  the leftmost N px at full height for representative image sizes.
- **`ShelfBooksLayout`** existing tests keep passing (the margin is applied by the caller,
  not the layout), adjusting any that assumed the full card width.
- Prior art: `ShelfBooksLayoutTests` (pure, seeded, network-free) is the model for these.

## Out of Scope

- Persisting the strip image or title colour in SwiftData (kept in memory only).
- Any painterly/watercolour effect on the strip beyond the title shadow (the shader is
  removed, not reworked).
- Refining the scrub's index mapping for the mixed (spines + pile) layout — stays linear.
- Filing a book onto a shelf, renaming/deleting shelves (ADR 0004 scope unchanged).
- Re-introducing UIKit anywhere other than the single scrub recognizer bridge.

## Further Notes

- Builds on ADR 0003 / 0004 and PRD 0001 (carousel + create). The `Edition.dominantColorHex`
  property from ADR 0003 becomes unused for spines once strips land; leave it or remove it
  in a follow-up cleanup.
- The UIKit recognizer must allow simultaneous recognition with the scroll view's pan so a
  swipe still scrolls; it arms only after the press duration, and re-enables scroll on end
  (including cancellation) so the carousel never gets stuck disabled.
- Keep the strip cheap: a ~10px-wide strip is tiny; stretching is done by the resizable
  `Image`, so the cached asset stays small.
