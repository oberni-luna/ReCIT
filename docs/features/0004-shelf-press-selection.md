# Press-and-hold to pick a book, with the screen dimmed around the shelf

Shipped on 2026-08-18. See ADR `docs/adr/0006-shelf-press-selection-scrim.md`.

## What it does

Press a book on a shelf and it grows under your finger on a springy curve; let go early and it
bounces back down, and even a quick tap makes it visibly swell and settle — that peek is how
you find out the shelf responds to a press. A swipe still scrolls the carousel. Keep holding
and, just as the book reaches full size, a blur blooms behind that shelf — its paper and the
neighbouring étagères go soft, fading out with no edge, while its books and plank stay sharp.
A haptic tick lands a moment later, as selection mode arms. From there, sliding anywhere moves
the growth to the book nearest your finger, every other scroll is frozen, and lifting opens
that book. Slide off the shelf and nothing is selected, so lifting there does nothing.

## Technical surface

- Screens touched: the shelves carousel cards (`Features/Shelves`) and `MainTabView` (the
  scrim has to cover the tab bar).
- New: `ShelfPressRecognizer` (a `UIGestureRecognizer` subclass reporting touch-down, the
  0.5s arm, moves and release), `ShelfPressGestureView` (its SwiftUI bridge),
  `ShelfFocusModel` (`@Observable @MainActor`: the focused card's screen frame),
  `ShelfFocusHaloView` (radially-masked `.ultraThinMaterial`, drawn as the background of the
  books-and-plank stack), `ShelfCardMetrics` (every card size from its width) and
  `ShelfDrawnBooks` (the capped, newest-first run).
- Removed: `ShelfBookSelection` and the carousel-wide selection, plus the deselect-on-swipe
  and deselect-on-tap-outside handlers — selection is transient again.
- `ShelfBooksView` now takes `grownIndex` + an animated `growth` instead of a fixed ×1.5.
- `ShelfBooksLayout` unchanged: `nearestIndex(to:)` and its tests carry over.

## Notable decisions

- The growth doubles as the progress indicator for the hold — no separate affordance.
- A tap peeks to ×1.15 whatever its length (springs are retargeted, so the presented scale
  can't be read back — a 250ms window on the press decides it instead).
- Selection is confined to the étagère the press started on, matching the scrim's focus.
- The blur sits inside the card rather than over the screen with the shelf cut out: any hole
  shows its own edge (flat white inside, blurred content just outside), and that edge was the
  artefact, not its shape.
- The focused card paints above its neighbours, because a material only blurs what is drawn
  beneath it.
- The blur comes in at 90% of the hold, not at the arm — landing with the book's growth instead
  of after it.
- A quick tap on a shelf now opens nothing; the shelf's list is on its name, and the flat
  list below is the fast path to a book.
