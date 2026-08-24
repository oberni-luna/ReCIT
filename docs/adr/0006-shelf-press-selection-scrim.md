# ADR 0006 — Press-and-hold book selection, with a focus overlay

- Status: Accepted
- Date: 2026-08-19
- Amended: 2026-08-24 — the copy follows the shelf while it scrolls (rule 5)
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

`ShelfFocusModel.Book` carries the item, its frame **in its card's coordinates**, how the shelf
presents it (standing, lying, or a lone cover) and whether it leans. Where the card itself sits
is a separate field, `cardOrigin`, and the overlay adds the two.

The split is not tidiness. The two move for different reasons: the frame within the card changes
only when the finger picks another book, while the card's place on screen changes whenever
anything scrolls. Summed once at press time — which is what this used to do — the copy stayed
where the shelf *had been*, and every point the page scrolled was a point of daylight between
the copy and the book it was drawn from. See "The copy is glued to the shelf, not to the screen"
below.

`cardOrigin` is published by the pressing card on **every layout pass** for as long as the press
lasts. The card's own `cardFrame` stays local `@State` and is likewise published on every pass,
not only while pressing — that is the bug that once put the redrawn book in the top-left corner
of the screen, and it is also why the first press has an origin to start from. Only the card that
owns the current `focus.book` writes the shared `cardOrigin`; `ownsFocus` says which one that is,
and it outlives `grownIndex`, which goes nil the moment the finger leaves the étagère while the
copy is still unwinding.

Shared pieces keep the shelf and its copy identical: `ShelfCardMetrics` (every size from the
card width), `ShelfDrawnBooks` (newest first, capped at 18), `ShelfBookTitle`, `ShelfCoverView`,
and `ShelfBookOrientation` — the last promoted out of `PaintedBookView`, because a type nested
in a generic view cannot be named without its type arguments.

### Five rules the animations follow

1. **Mount a frame before animating.** `growUp()` defers through `Task { @MainActor in … }`. A
   view inserted in the same transaction as its own animation has no earlier value to travel
   from, so SwiftUI draws it at the target: the book appeared at ×2 instantly, and no amount of
   curve-tuning changed it, because the animation was never playing. The same order applies when
   the finger returns to the shelf, since the copy is inserted afresh.
2. **Nothing animates from one book to the next.** The finger is picking, and a cover morphing
   into another cover reads as a glitch — so `moveTo` publishes without `withAnimation`, and
   `PaintedBookView` does not fade its strip in.
3. **The exit mirrors how far the entrance got** — unless the shelf is being scrolled.
   `releasePress` measures the press and unwinds over that long, capped at the hold and floored
   at 0.12s: a tap whose book had barely begun to grow drops straight back, while a full hold
   takes the full hold to come apart. Sliding off the shelf unwinds the same way, and sliding
   back on winds it up again. The book is handed back (`focus.book = nil`) only once the shrink
   finishes, and only if the finger has not returned meanwhile — otherwise the overlay vanishes
   mid-animation. The exception is a press the finger *travelled* out of: that one takes the
   floor, for the reason rule 5 gives.
4. **Opening a book drops the overlay outright**, without animating
   (`ShelfFocusModel.reset()`). The detail screen is about to cover the shelf, and an overlay
   unwinding on top of it reads as a leftover from the previous screen.
5. **The copy is positioned relative to the shelf, never to the screen.** Everything here
   moves — the page scrolls, the carousel snaps, the large title collapses and springs back — so
   the card's origin is republished every layout pass and summed with the book's frame at draw
   time. The corollary is that a press the finger scrolled out of leaves at the floor rather
   than mirroring: the origin trails the scroll by a frame, and the shortest exit is the one
   that shows it least. See the section below.

An earlier rule, a guaranteed "peek" (a tap bouncing the book to ×1.15 regardless), was removed:
it contradicted rule 3, since the bounce made a tap take longer to settle than it took to grow.

### The copy is glued to the shelf, not to the screen

Press a book, then swipe: the recogniser hands the touch back past `slop`, the scroll view takes
it, and the copy unwinds. It used to unwind *where the shelf had been*. The étagère slid out from
under it and the grown book was left hanging over the page — landing, as the report put it, in
mid-air. Because the shelf never stops drawing its own book, this was not one book out of place
but two books at once: the real one riding the scroll, the copy standing still.

The frame was the whole of it. `cardOrigin` now travels with the card, so the copy travels with
the shelf.

That leaves one gap, and it is worth stating rather than discovering. `onGeometryChange` runs
during layout and the state it writes lands on the *next* pass, so the origin trails the scroll
by a frame — on a hard flick, a hundred points of it. So the exit is cut short too:

- **`ShelfPressRecognizer.Cancellation`** now says why a press ended without arming — `lifted`,
  `travelled`, or `interrupted`.
- A **lift** is a tap and keeps rule 3's mirror.
- A **travel** takes the floor (0.12s) instead. The scroll view's slop and this recogniser's fire
  at about the same instant, so the shelf starts moving exactly when the copy starts unwinding;
  every millisecond of that unwind is a millisecond in which a frame of lag could show. An
  interruption is treated the same — the touch has gone elsewhere either way.

Between 0.25s and 0.5s the veil is already partly in, so a travel now takes it out in 0.06s
rather than 0.25s. Deliberate: the page is scrolling, and the veil has no business there.

A card can also be torn down mid-press — the carousel is lazy and a hard flick recycles it. Then
nobody republishes the origin and nobody hands the copy back, so the owning card resets the focus
outright on `onDisappear`.

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
  orientation are shared views rather than inline code. Anything that *moves* a book has to reach
  both as well, and that one is harsher: a book drawn wrong is ugly, a book placed wrong reads as
  a second copy of itself.
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
- **Nothing about the copy's position may be computed once.** Everything on this screen moves:
  the page scrolls, the carousel snaps, the large title collapses and springs back. A value
  sampled at press time is stale by the next frame. Publish it every layout pass, or derive it
  from something that is.
