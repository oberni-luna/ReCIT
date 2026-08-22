## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

What a save looks like on a grid, from the first write to a failure halfway.

- **While the run writes**: the grid and the carousel drop to 80 % opacity and stop accepting
  touches. The étagères **the plan writes to** breathe — scale 1,00 ↔ 1,02, 1,2 s,
  `easeInOut`, in phase across cards — and the one in flight carries a spinner. Étagères the
  plan does not touch neither dim nor breathe: one that nobody is writing to must not look
  like one waiting its turn.
- **As each étagère lands**: back to full opacity, and its visible covers bounce in one at a
  time, 0,08 s apart — the stagger the onboarding plank already uses.
- **A failed étagère keeps a warning badge** after the run settles. Étagères never attempted
  return to normal and keep their work in the stack, so pressing « Appliquer » again sends
  exactly the remainder.
- **The footer's text slot has four readings**, growing upward and pushing the grid as it
  needs to:
  - idle with a pending stack, and **throughout the run**: the recap. It is derived from the
    write plan, and the plan shrinks as landings trim the stack — so the recap *is* the
    progress. No second counter, no new plural strings, and no way for the two to disagree.
  - a run that finished: the existing success report, including the "nothing to save" wording
    for a stack that cancelled itself out.
  - a run that stopped: the existing three-part report — what landed, where it broke (which
    may exist without its books), what was never touched — and that pressing the button again
    finishes it.
  - a proposal that came back empty: « aucun rangement à proposer ».
- The breathing and the bounces are **kept under Reduce Motion**, on the owner's call; the
  spinner is what carries the information for a user with animations turned down. Recorded as
  a deliberate divergence.

## Acceptance criteria

- [ ] During a save, the whole library dims to 80 % and no gesture is accepted.
- [ ] Only the étagères the plan writes to breathe, and the one being written carries a
      spinner.
- [ ] Each étagère snaps to full opacity as it lands, and its visible covers bounce in one at
      a time.
- [ ] A run that breaks leaves a warning badge on the étagère it broke on, after the run has
      settled.
- [ ] Étagères never attempted look untouched and their work stays pending.
- [ ] The recap counts down as the run lands, with no separate progress string.
- [ ] A stopped run shows the three-part report in the footer, which grows and pushes the grid
      up rather than truncating.
- [ ] Pressing « Appliquer » after a failure sends only what is left.
- [ ] An empty proposal is reported in the same slot.
- [ ] The existing ledger and landing test suites still pass untouched.

## Blocked by

- `issues/0046-grid-sorting-surface-read-only.md`
