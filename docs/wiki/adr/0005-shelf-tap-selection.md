# ADR 0005 — Tap-to-select on the shelf (replacing the hold-and-scrub)

- Status: Accepted
- Date: 2026-08-18

## Context

ADR 0003 shipped the shelf gesture as *tap the shelf → open its list*, plus *hold then
slide → scrub the books*, which PRD 0002 then rebuilt on a `UILongPressGestureRecognizer`
because SwiftUI could not compose hold-then-drag inside a snapping carousel.

Two problems remained:

1. **The scrub is undiscoverable.** Nothing on screen suggests a 0.2s press, and the one
   deliberate UIKit exception in the codebase existed only to serve it.
2. **The index mapping was wrong on full shelves.** `ScrubMapping` interpolated linearly
   across the books width, but a full shelf renders spines in the left half and a *vertically
   stacked* pile in the right half — so in the pile the finger's x said nothing about which
   book it was over.

Separately, a book lying flat in the pile was painted with the *upright* cover sliver: the
cover's height was squeezed into ~20pt of thickness, which read as horizontal banding
instead of a spine seen side-on.

## Decision

> **The interaction below is superseded by ADR 0006**, which returns to a single
> press-and-hold gesture (with a focus scrim). The geometric hit testing and the
> quarter-turned cover sliver decided here still stand.

**Interaction — two plain taps, no press-and-hold.**

- A tap anywhere on the shelf card (books zone *or* plank) grows the book **nearest** the
  tap and drops any other one back into place.
- A tap that resolves to the already-grown book **opens** it (`NavigationDestination.book`).
  The test is "nearest is the selected one", not "inside its enlarged bounds", so a tap
  slightly off a grown spine still opens it rather than selecting a neighbour.
- The shelf's own list moved to its **name**, now a button under the card. `.shelf(id:)`
  is otherwise unreachable from the card.
- Selection is held **once for the whole carousel** (`ShelfBookSelection { shelfId, index }`
  in `ShelvesContent`), so only one book ever stands out; tapping a book on another étagère
  moves it. It clears on navigating into a book, on **any swipe** (either scroll view leaving
  `.idle`, via `onScrollPhaseChange`) and on **a tap that lands on no étagère** (a handler on
  the page's content, which a card's or a row's own tap never reaches).
- `ScrubGestureView` and `ScrubMapping` are **deleted** — with no drag left, nothing fights
  the carousel scroll, so `scrollDisabled` and the `scrubbing` binding go too. The UIKit
  exception is gone; a location-carrying `onTapGesture` is enough (the tap *needs* its
  location, which is the codebase's stated bar for choosing it over `Button`).

**Hit testing — real geometry, in the layout type.**

`ShelfBooksLayout` now owns `spineFrame(at:)`, `pileBarFrame(at:)` and `nearestIndex(to:)`
in books-zone coordinates. Standing runs are centred (all-vertical) or hard left (mixed);
a mixed shelf splits at mid-width, resolving **by x among the spines** and **by y within
the pile**. `nearestIndex` never returns nil on a non-empty shelf: a tap past the run,
above the books or on the plank clamps to the closest book. `ShelfRowView` builds the
layout and passes it to `ShelfBooksView`, so what is hit-tested and what is drawn cannot
diverge.

**Lying books — quarter-turned cover sliver.**

`SpineStripLoader.Strip` carries a second image: the same sliver turned a quarter turn
(`turnedQuarter`, real pixels redrawn through a `CGContext` rather than a `UIImage`
orientation flag, so the result is unambiguous). `PaintedBookView` takes an `Orientation`
(`.standing` / `.lying`) and stretches the matching image, so a pile book shows the cover
along its length and the sliver stretches vertically over its thickness.

## Consequences

- Discoverable and one-handed: no timed press, and the whole card is a target.
- Hit testing is pure and unit-tested (frames, centring, the left/right split, the pile's
  bottom alignment) — the class of bug that made pile scrubbing wrong is now covered.
- No UIKit in the shelf feature at all.
- A shelf card no longer opens its list on a body tap; anyone looking for that behaviour
  must go through the name button. This is the one regression in reach, accepted to free
  the card's surface for book selection.
- The second strip image doubles the per-edition strip cache (still ~10×H px, built once).
- Supersedes the interaction section of ADR 0003 and the scrub half of PRD 0002.
