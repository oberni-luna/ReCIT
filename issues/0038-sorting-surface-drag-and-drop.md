Title: Dragging a book from one section to another, writing nothing
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

The gesture. A book is dragged from any section onto any other — étagère to étagère, étagère to
`À ranger`, `À ranger` to étagère — and the screen redraws with it moved. Nothing is written.

Each gesture pushes onto an ordered stack of changes; the screen renders the snapshot with the
stack applied. `List`'s built-in move cannot do this: it reorders inside one section and never
crosses sections, so this needs draggable rows and drop destinations with a typed transfer
carrying the book's identity, the target being a `SortSection`. There is therefore no edit mode,
and the handle stays an affordance rather than a reorder grip.

The third button now follows the stack: not empty means `Annuler`, which discards every pending
change and returns the screen to its snapshot. Empty means `Terminer`. The rule is derived from
the stack, never from a flag — a flag would leave the screen's only destructive button labelled
`Terminer`.

The session state moves into an app-scoped observable model at this point, because the following
slice's writes must outlive the screen.

## Acceptance criteria

- [ ] A book can be dragged between two étagères, from an étagère to `À ranger`, and back
- [ ] The drop lands on the section, and the section shows it is the target while the finger is
      over it
- [ ] Every move pushes one change; the rendered sections are the snapshot with the stack applied
- [ ] A book is never in two sections, at any point of the gesture
- [ ] Counts in the section headers follow the moves
- [ ] With a non-empty stack, the third button reads `Annuler`; pressing it restores the snapshot
      exactly and the button returns to `Terminer`
- [ ] Leaving the screen and coming back keeps the stack
- [ ] The stack and the projection are asserted without a store or a view

## Blocked by

- issues/0036-sorting-surface-missing-states.md
- issues/0037-sorting-surface-read-only.md
