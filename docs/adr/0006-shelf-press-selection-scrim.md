# ADR 0006 — Press-and-hold book selection, with a focus overlay

- Status: Accepted
- Date: 2026-08-19
- Supersedes: the interaction half of ADR 0005 (tap-to-select)

## Context

ADR 0005 replaced the hold-and-scrub with two taps: tap grows the nearest book, tap again opens
it. In use it read as two unrelated actions rather than one continuous gesture, gave no feedback
while the finger was down, and left a book grown after the finger was long gone.

The gesture we want is one continuous press: the shelf answers immediately, tells you when it
has taken over, then follows the finger. That needs a touch-down signal *before* recognition,
which `UILongPressGestureRecognizer` cannot give, and it has to survive inside a snapping
carousel.

## Decision

### The gesture, in five beats

Everything below is timed off `ShelfPressRecognizer.holdDuration`, so the whole gesture rescales
from that one constant.

1. **Touch down** — the book under the finger starts growing towards ×2 on a spring (bounce
   0.35), centred on itself. Sprung rather than eased so a tap answers at once: an `easeIn`
   curve starts so slowly that a tap looked like nothing had happened. The growth *is* the
   progress indicator. Travel more than 10pt first and the recogniser gives the touch back —
   the carousel keeps the swipe.
2. **Halfway through the hold** — the veil starts coming in, over the remaining half. Not
   sooner: a single tap would otherwise flash the whole screen for an instant.
3. **End of the hold** — selection mode arms: a medium impact haptic, and the pressed book's
   cell fades in above it.
4. **Slide** — the growth follows the finger to the nearest book, one selection tick per book
   crossed. Off the étagère, nothing is selected and selection mode unwinds.
5. **Lift** — opens the grown book; lifting with nothing selected does nothing.

A quick tap therefore opens nothing at all: the shelf's list is on its name button, and the flat
list below is the fast path to a book.

### A custom recognizer, not `UILongPressGestureRecognizer`

`ShelfPressRecognizer` (a `UIGestureRecognizer` subclass) reports `pressBegan` from
`touchesBegan`, fires `onFocusing` halfway through a cancellable `Task` sleep, arms at the end,
then drives `moved` / `ended` / `cancelled`. It sets `cancelsTouchesInView = false`, recognises
simultaneously with the carousel's pan, and does not claim the touch until it arms — so before
the hold a swipe scrolls exactly as before. This is the feature's only UIKit code; SwiftUI still
cannot compose hold-then-drag inside a snapping scroll view.

Both scroll views take `.scrollDisabled(focus.isArmed)` so the slide moves the selection and
nothing else. The finger is stationary when this flips, so no in-flight pan is interrupted.

### Focus is an overlay over the whole app, and only the pressed book crosses into it

`ShelfFocusOverlayView`, hosted by `MainTabView`, draws three things, with
`allowsHitTesting(false)` throughout so the finger keeps talking to the shelf's recogniser
underneath — which is what lets the slide keep choosing books.

**The veil.** A screen-filling `.ultraThinMaterial` washed with `backgroundDefault`, capped at
half opacity. The rest of the étagère has to stay readable underneath — the finger needs to see
where it is going — and a material at half opacity half-blurs, which is exactly the effect. Its
opacity rides `focus.progress`, so the screen recedes as the book grows.

**The pressed book alone**, redrawn sharp above the veil, grown ×2 about its centre. The shelf
keeps drawing its own book underneath and the copy never fades: at rest the copy sits exactly
over the original, and by full growth it covers it entirely (concentric, twice the size). Fading
the copy was tried and read as a ghost — two versions of the same book at partial opacity. The
copy also draws no placeholder (`PaintedBookView.showsPlaceholder`, and `ShelfCoverView`'s
likewise): the real book underneath is a better one than parchment, which at ×2 is a pale slab
twice the size of the book.

**The cell**, `ShelfFocusBookCell`, once selection mode arms. Cover, title and authors, no
subtitle and no transaction tag — this is read at a glance with a thumb on the shelf, not
browsed. The row is bottom-aligned and the cover keeps the book's own proportions (48pt wide,
natural height, small drop shadow) so a tall paperback and a squat art book both look like
themselves. Its backdrop fades in from nothing, peaks at 90% in the middle and fades back out,
lifting the text off the veiled shelf without drawing an edge at either end.

The cell rests **above** the grown book so a thumb on the shelf never covers it, on a line fixed
per shelf: `ShelfBooksLayout.topOfTallestBook(grownBy:)` — the height the *tallest* book reaches
once grown (half the growth going up, half down, since growth is centre-anchored). Set by the
tallest book rather than the pressed one, it clears every book on the shelf and never moves as
the finger slides between books of different heights. It is laid out as a box running from the
top of the screen down to that line, with the cell pinned to the box's bottom — which places it
without anyone having to know how tall its text runs.

A `fullScreenCover` would cancel the tracked touch outright, and a second `UIWindow` would too
unless carefully kept non-key and non-interactive — neither buys anything an overlay at the tab
host does not already give, and the status bar stays sharp either way because it is a system
layer above the app's window.

### What crosses over

`ShelfFocusModel` (`@Observable @MainActor`) holds the pressed book, the press's progress, the
growth, and whether it armed. The card mutates it inside `withAnimation`, so the overlay
animates with it.

`ShelfFocusModel.Book` carries the item, its frame in screen coordinates, how the shelf presents
it (standing, lying, or a lone cover) and whether it leans. The frame comes from
`ShelfBooksLayout.bookFrame(at:)` plus the card's own global frame — published on **every layout
pass**, not only while pressing, which is the bug that once put the redrawn book in the top-left
corner of the screen.

Shared pieces keep the shelf and its copy identical: `ShelfCardMetrics` (every size from the
card width), `ShelfDrawnBooks` (newest first, capped at 18), `ShelfBookTitle`, `ShelfCoverView`,
and `ShelfBookOrientation` — the last promoted out of `PaintedBookView`, because a type nested
in a generic view cannot be named without its type arguments.

### Four rules the animations follow

1. **Mount a frame before animating.** `growUp()` defers through `Task { @MainActor in … }`. A
   view inserted in the same transaction as its own animation has no earlier value to travel
   from, so SwiftUI draws it at the target: the book appeared at ×2 instantly, and no amount of
   curve-tuning changed it, because the animation was never playing. The same order applies when
   the finger returns to the shelf, since the copy is inserted afresh.
2. **Nothing animates from one book to the next.** The finger is picking, and a cover morphing
   into another cover reads as a glitch — so `moveTo` publishes without `withAnimation`, and
   `PaintedBookView` does not fade its strip in.
3. **The exit mirrors how far the entrance got.** `releasePress` measures the press and unwinds
   over that long, capped at the hold and floored at 0.12s: a tap whose book had barely begun to
   grow drops straight back, while a full hold takes the full hold to come apart. Sliding off
   the shelf unwinds the same way, and sliding back on winds it up again. The book is handed
   back (`focus.book = nil`) only once the shrink finishes, and only if the finger has not
   returned meanwhile — otherwise the overlay vanishes mid-animation.
4. **Opening a book drops the overlay outright**, without animating
   (`ShelfFocusModel.reset()`). The detail screen is about to cover the shelf, and an overlay
   unwinding on top of it reads as a leftover from the previous screen.

An earlier rule, a guaranteed "peek" (a tap bouncing the book to ×1.15 regardless), was removed:
it contradicted rule 3, since the bounce made a tap take longer to settle than it took to grow.

### The cover strip, keyed to its book

`PaintedBookView` keys its strip to the edition it was painted from. It used to keep the first
strip it ever loaded, which was invisible on a shelf (each spine has a stable edition) but wrong
in the overlay, where one view is reused for every book the finger crosses — it kept painting
the first book's cover onto all the others. Keying it fixes correctness; a main-actor mirror of
the loader's cache (`SpineStripLoader.cachedStrip(forEditionUri:)`) fixes the flicker that
correctness alone would cause, since awaiting the actor for an already-cached strip still costs
a frame of placeholder.

### Four earlier attempts at the veil, each of which looked correct in code

1. *Black at 40% with the card cut out.* Far too heavy, and since the shelf's paper and the page
   behind it are near-white, the cut-out read as a bright lightbox.
2. *Tightening the cut-out to the tallest book.* No help — the white is between and behind the
   spines, not above them.
3. *Blur with the card cut out.* Still a rectangle: flat white inside the hole, blurred smudges
   just outside. The discontinuity **is** the artefact, so no hole can be the answer.
4. *A blur inside the card, under the plank.* No edge, but the carousel's scroll view clips it,
   so it could never leave the carousel row.

The lesson across all four: nothing that stays inside the card can veil the screen, and nothing
that veils the screen can leave part of the card out of it. The way through is to veil
everything and bring back what must stay legible — one book and one cell, not a shelf.

## Consequences

- The gesture is continuous and self-explanatory: pressing anything gives feedback at once, and
  the haptic plus the veil make the mode change unmistakable.
- The pressed book is drawn twice at once — by the shelf and, over it, by the overlay. Anything
  that changes how a book looks has to reach both, which is why the title, the cover and the
  orientation are shared views rather than inline code.
- The overlay veils the nav bar and the tab bar. Keeping the nav bar sharp would mean hosting
  the overlay inside the `NavigationStack` (leaving the tab bar sharp too) or cutting its rect
  out — the hard-edged artefact this ADR exists to avoid.
- UIKit is back in the feature, in one file, for the reason ADR 0005 had already recorded.
- `ShelfBooksLayout` keeps `nearestIndex(to:)` and its frame math from ADR 0005 and gains
  `bookFrame(at:)`, `coverFrame`, `tallestBookHeight` and `topOfTallestBook(grownBy:)`, all
  covered by tests.

### Traps for the next person

- **Do not extend the `@Model` classes** from the shelves feature. An extension on `Shelf`
  returning `[InventoryItem]` broke that macro's expansion and surfaced as "`SearchResult` does
  not conform to `Hashable`" in an unrelated file. `ShelfDrawnBooks` is a plain namespace type
  for exactly this reason.
- **Nothing oversized goes into the card's `ZStack`.** A layer taller than the stack makes the
  stack grow, and the outer `.frame(height:)` then centres — and shifts — the whole shelf. Use a
  `.background`, which never influences its host's layout.
- **A view cannot animate the transaction that inserts it.** See rule 1 above; it cost an
  afternoon of tuning curves that were never running.
