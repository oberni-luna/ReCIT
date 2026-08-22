## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

The gesture the whole screen exists for: a book dragged from the carousel onto an étagère,
from an étagère onto another, and from an étagère back down into the carousel.

- **Payload**: `SortBookTransfer`, a book id under an **app-private `UTType`** — never a
  plain `String`, which would let a book be dropped into Notes or Messages. The origin does
  **not** travel: the session resolves it from the projection, so a payload cannot name a
  stale origin.
- **Preview**: the book's cover.
- **Sources**: a book card in the carousel, and the **topmost cover only** of an étagère card.
  The rest of the card taps through to the detail screen. The narrow source is deliberate and
  matches the app's grammar — in the inventory a book is pressed, not its card (ADR 0006).
- **Targets**: the whole étagère card, title included, and the whole « à ranger » panel —
  order there is arrival order, so aiming at a slot would mean nothing.
- **Hover**: card scale 1,03 with an accent border, one `impact(.soft)` on entry only.
- **Landing**: the arriving cover appears at scale 1,15 and −12 pt in Y and settles on
  `.spring(response: 0.32, dampingFraction: 0.55)`, with an `impact(.light)`. It lands on top
  of the pile, which is where it will be picked up from — so a mis-drop is undone by the
  reverse gesture.
- **Autoscroll**: the grid scrolls while a drag is held near its top or bottom edge. If
  slice 0044 found the system does not provide it, 60 pt sensitive bands drive a
  `ScrollViewReader` instead.
- **A drop on the section the book already sits in does nothing** — no change, no bounce, no
  haptic. `SortChange.move` already returns `nil` for it; the silence is the point.
- **While a run owns the stack** (`isBusy`), both regions stop accepting touches. The model
  already refuses the write; a drag that starts and achieves nothing is worse than one that
  cannot start.

If the gesture does not take on device, the fallback is a `DragGesture` with an overlay
redrawing the cover under the finger and targets resolved from `anchorPreference` — the
mechanism `ShelfFocusOverlayView` uses. It is a rewrite of this slice and of nothing else.

## Acceptance criteria

- [ ] Dragging a book from the carousel onto an étagère card files it there, landing on top of
      the pile with the bounce and the haptic.
- [ ] Dragging the topmost cover of an étagère onto another étagère moves the book between
      them.
- [ ] Dragging the topmost cover of an étagère onto the panel takes the book off that étagère
      and back among the books to file.
- [ ] The counts in both section headers and on the cards follow every drop immediately.
- [ ] A card under the finger grows and takes its accent border, and buzzes once on entry
      only.
- [ ] Dropping a book back on its own section records nothing: the discard control stays
      inert and « Appliquer » stays as it was.
- [ ] The drag preview is the book's cover.
- [ ] A book cannot be dropped outside the app.
- [ ] Tapping anywhere on an étagère card still pushes its detail screen; tapping a book card
      does nothing.
- [ ] The grid scrolls while a drag is held at its edges.
- [ ] Nothing can be dragged while an apply or a proposal is in flight.

## Blocked by

- `issues/0044-verify-grid-drag-and-drop.md`
- `issues/0046-grid-sorting-surface-read-only.md`
