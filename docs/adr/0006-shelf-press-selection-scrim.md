**Focus is a blur drawn inside the card.** `ShelfFocusHaloView` is a material — which blurs
whatever is drawn beneath it — sized well past the card and masked by a `RadialGradient` so it
fades out with no edge. It is the `.background` of the books-and-plank stack, which puts it
above the shelf's paper and below the books: the paper and the neighbouring étagères go soft
while the books and the plank stay sharp, with nothing redrawn anywhere.

Two placement rules make it work:

- **A background, not a `ZStack` layer.** As a layer it became the stack's tallest child, the
  stack grew, and the outer `.frame(height:)` centred the oversized content — sliding the whole
  shelf down half the extra height. A background never influences its host's layout.
- **The focused card paints last** (`.zIndex` in the carousel, driven by `focusedShelfId`). A
  material only blurs what is composited beneath it, so a neighbour drawn after this card would
  both stay sharp and paint over the halo.

The carousel's scroll view clips the halo, so the blur stops at the carousel row — the page
heading above and the book list below stay sharp. That is invisible in practice: the strip
immediately above and below a card is empty paper, and blurring empty paper shows nothing.

Four earlier attempts are worth recording, because each looked correct in code:

1. *Black at 40% with the card cut out.* Far too heavy, and since the shelf's paper and the
   page behind it are near-white, the cut-out read as a bright lightbox.
2. *Tightening the cut-out to the tallest book.* No help — the white is between and behind the
   spines, not above them.
3. *Blur with the card cut out.* Still a rectangle: flat white inside the hole, blurred smudges
   just outside. The discontinuity **is** the artefact, so no hole can be the answer.
4. *A screen-wide blur with the shelf redrawn sharp above it* (the trick iOS uses to lift a row
   out of a list for a context menu). It works in principle and escapes the carousel's
   clipping, but it means rendering the shelf twice, keeping the two copies in step through
   shared state, and publishing the card's screen frame — a lot of machinery, and a whole class
   of alignment bugs, to blur a region that is empty paper anyway.

**Scrolls freeze while focused.** Both the page's vertical scroll and the carousel's horizontal
one take `.scrollDisabled(focus.isFocused)`, so the slide moves the selection and nothing else.
The finger is stationary when this flips, so no in-flight pan is interrupted.

**The scrim blurs; it does not darken.** `ShelfScrimView` covers the screen with
`.ultraThinMaterial` and punches the focused shelf out of it — `ShelfScrimShape` (a `Shape`, so
the fill can be a material, which blurs its own backdrop) filled even-odd, `ignoresSafeArea`,
hit-testing off. `MainTabView` owns it so it reaches the nav bar and tab bar.

A black wash at 40% came first and was wrong twice over. It read as far too heavy for what is
only a focus hint; and because the shelf's paper and the page behind it are near-white,
clearing the card turned it into a bright lightbox. Tightening the hole to the tallest book did
not help — the white is *between and behind* the spines, not above them — so the card ended up
dimming its own paper under the books, a second layer that had to track the first pixel for
pixel. Blur removes the whole problem: nothing gets brighter or darker, so the shelf needs no
counter-layer and there is one rectangle instead of two.

(For the record, the card's dim layer had to be a `.background`, not another `ZStack` layer: as
a layer it became the stack's tallest child, the stack grew, and the outer `.frame(height:)`
centred the oversized content — sliding the whole shelf down half the extra height while the
hole stayed put. Worth knowing if anything is ever layered into that stack again.) It has to cover the nav bar and tab bar, which the shelves screen cannot reach, so
`MainTabView` owns it and reads a shared `ShelfFocusModel` (`@Observable @MainActor`,
`focusedCard: CGRect?` in screen coordinates) that it injects into the environment.
`ShelfRowView` publishes its own frame with `onGeometryChange(for:)`, expanded upward by the
zoom headroom so a book grown above the plank isn't clipped by the dim.

**The press's state stays in the card**, as `@State`. Only the focused shelf's id is shared
upward, as a binding to the carousel, for the scroll freeze and the z-ordering.

Two extractions came out of the redraw attempt and were kept because they are worth having on
their own: `ShelfCardMetrics` (every size derived from the card width — plank, zone, headroom,
margins, touch box) and `ShelfDrawnBooks` (newest first, capped at 18).

## Consequences

- The gesture is continuous and self-explanatory: pressing anything gives feedback at once,
  and the haptic plus the dimming make the mode change unmistakable.
- Selection is transient again. `ShelfBookSelection` and the carousel-wide selection state are
  deleted, and with them the deselect-on-swipe / deselect-on-tap-outside handlers — a press
  that ends always tidies up after itself.
- A shelf card now responds to *nothing* short of a deliberate hold: no tap target for the
  shelf list (that moved to the name in ADR 0005), and no quick way to open a book from a
  shelf. Accepted: the flat list below covers fast access.
- UIKit is back in the feature, in one file, for the reason ADR 0005 had already recorded.
- The scrim couples the shelves feature to `MainTabView` through `ShelfFocusModel`. That is
  the price of dimming the tab bar; the model stays deliberately two properties wide.
- `ShelfBooksLayout` is untouched: `nearestIndex(to:)` and the frame math from ADR 0005 are
  exactly what the slide needs, and they keep their tests.
- The blur is confined to the carousel row, and only reaches neighbours on the side that
  happens to paint first — plus the focused card's own z-index bump. Anything added to the card
  *above* the books-and-plank stack will not be blurred.
- The blur arrives before the haptic (90% vs 100% of the hold), so the scroll freeze does too.
  The finger is stationary at that point either way.
- `.ultraThinMaterial` is the knob for how insistent the focus feels; a heavier material frosts
  more, and `haloRadius` / `solidFraction` set how far it spreads.
- Trap for the next person: **do not extend the `@Model` classes** from the shelves feature. An
  extension on `Shelf` returning `[InventoryItem]` broke that macro's expansion and surfaced as
  "`SearchResult` does not conform to `Hashable`" in an unrelated file. `ShelfDrawnBooks` is a
  plain namespace type for exactly this reason.

## Risk to watch

Flipping `.scrollDisabled` mid-touch is expected to cancel only the scroll view's own pan. If
it turns out to cancel the tracked touch as well (ending the scrub the instant it arms), the
fallback is to leave scrolling enabled and have the recognizer's delegate stop recognising
simultaneously with the pan once armed.
