## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

Prove, before the surface is rebuilt on top of it, that SwiftUI's own drag and drop takes in
the containers this feature needs. Feature 0009 recorded that `draggable` /
`dropDestination` "simply did not take" on device; the diagnosis is that the payload was
attached to `List` rows **in edit mode**, where the list's reorder recogniser owns the long
press. That diagnosis is what this slice tests.

A throwaway harness — a grid of plain cards and a horizontal carousel of plain cards, wired
to a `print` — driven in the simulator by UI automation. Three questions, three answers,
written into this issue when it closes:

1. Does `.draggable` fire from a cell of a `LazyVGrid` inside a `ScrollView`, onto a
   `.dropDestination` sibling?
2. Does it fire from a cell of a `LazyHStack` inside a **horizontal** `ScrollView`, whose pan
   gesture competes with the long press?
3. Does the vertical `ScrollView` **autoscroll** while a drag is held near its top or bottom
   edge?

The harness is scratch code and is not committed. What is committed is the verdict, recorded
here, and — if question 3 answers no — the sensitive-band fallback design that slice 0047
will implement (60 pt bands at the grid's edges driving a `ScrollViewReader`).

Device verification is deferred to the owner's final pass. If the gesture fails there, the
fallback is a `DragGesture` with an overlay redrawing the cover under the finger and targets
resolved from `anchorPreference` — the mechanism `ShelfFocusOverlayView` already uses
(ADR 0006), and a rewrite of slice 0047 alone.

## Acceptance criteria

- [ ] A harness exercises drag from a `LazyVGrid` cell to a sibling card, and the drop is
      observed in the simulator.
- [ ] A harness exercises drag from a horizontal `LazyHStack` cell to a card outside the
      carousel, and the drop is observed in the simulator.
- [ ] Autoscroll behaviour during a held drag is observed and recorded as yes or no.
- [ ] The three verdicts are written into this issue file.
- [ ] No harness code remains in the repository.
- [ ] If autoscroll is absent, the fallback design is stated here precisely enough for 0047
      to implement without re-deciding it.

## Blocked by

None - can start immediately.
