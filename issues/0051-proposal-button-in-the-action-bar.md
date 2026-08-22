## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

The on-device model as one round button among the user's own gestures, in a bar whose shape
follows what the phone can do.

- The bar is **annuler | Appliquer | proposer**, in that order: a round icon button, the
  primary pill, a round icon button.
- **A phone that cannot run the model gets no proposal button** — the bar has two controls and
  « Appliquer » takes the space. A control that can never work is worse than none.
- **Apple Intelligence switched off, or a model still downloading**, keeps the round button,
  inert, and **a tap explains why** — with the route to the Settings switch when one exists.
  The reason is still said out loud, as feature 0009 decided, but on demand: the footer slot
  belongs to the recap now, and availability is read live from the observable
  `SystemLanguageModel`, so switching Apple Intelligence on and coming back re-renders it with
  no relaunch.
- **While a proposal is being worked out**: the round button becomes a spinner of the same
  diameter, the grid and carousel drop to 80 % **without breathing** — nothing is being
  written, and it must not look like a save — and no gesture is accepted.
- **When a proposal lands**: the cards it touched bounce their new books in, left to right,
  0,08 s apart. It is the largest change of the session, and without motion the screen simply
  jumps. Drafts the proposal invented appear as new cards in the same pass.
- A proposal that adds nothing is reported in the footer slot (« aucun rangement à
  proposer »), since the SnackBar does not draw above the modal.
- Nothing else about the pipeline changes: the proposal arrives as ordinary changes on the
  same stack, adjustable by dragging and discardable like any other pending work.

## Acceptance criteria

- [ ] The bar reads annuler | Appliquer | proposer, and drops to two controls on an ineligible
      device with « Appliquer » widening.
- [ ] With Apple Intelligence off, the round button is inert and tapping it explains why, with
      a route to Settings.
- [ ] Switching Apple Intelligence on and returning makes the button live without relaunching
      the app.
- [ ] While a proposal runs, the button is a spinner, the library dims without breathing, and
      no drag or tap is accepted.
- [ ] A landing proposal bounces the affected cards' new books in, left to right, and new
      drafts appear as cards in the same pass.
- [ ] A proposal that adds nothing says so in the footer slot.
- [ ] A landed proposal can be adjusted by dragging and thrown away by the discard control.

## Blocked by

- `issues/0050-apply-feedback-on-the-cards.md`
