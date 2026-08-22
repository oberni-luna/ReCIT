## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

The written record of what shipped, and of the one decision that outlives this feature.

- **An ADR for the modal flow**: one container owning the cover, its stack, its close control
  and its ending; a start route rather than two presentations of one screen; routes local to
  the flow; an app-wide navigation enum that gets *smaller* as a flow gets richer; and closing
  a flow keeping its draft. The next flow will cite it, which is why it is an ADR and not a
  paragraph in a feature doc.
- **A feature doc** (`docs/features/0010-…`) saying what the screen does, what it supersedes,
  and — the part that matters most to the next reader — that it supersedes only the
  **surface** of feature 0009. The frozen snapshot, the change stack, the write plan as a diff
  and the resumable awaited apply are that feature's and are untouched.
- The notable decisions worth writing down, each with its reason: the dirty flag considered
  and rejected; arrival order replacing `displayOrder`; geometry and pile extracted as pure
  modules; the drag retried after the 0009 failure and why the diagnosis was edit mode; the
  narrow drag source on a card; the anchored panel as content rather than chrome; « Terminer »
  disappearing into the close control; the animation kept under Reduce Motion with a spinner
  as its accessible reading; and the SnackBar not drawing above the cover, accepted because
  the screen names its own failures.
- The known gaps carried over: the apply-ordering gap inherited from feature 0009, and the
  device verdict on the gesture.
- The index of shipped features in `CLAUDE.md` gains its line, and the issues list at the foot
  of the feature doc names each slice with its commit.

## Acceptance criteria

- [ ] An ADR exists for the modal flow, numbered after the last one, with context, decision
      and consequences.
- [ ] A feature doc exists, states what it supersedes and what it explicitly does not, and
      lists the notable decisions with their reasons.
- [ ] `CLAUDE.md`'s shipped-features index has its line, in the existing format.
- [ ] Every slice of this PRD is listed with its commit hash.
- [ ] Known gaps are written down rather than implied.

## Blocked by

- `issues/0047-drag-a-book-between-sections.md`
- `issues/0048-new-shelf-tile-and-drop-to-create.md`
- `issues/0049-pending-shelf-detail-screen.md`
- `issues/0051-proposal-button-in-the-action-bar.md`
- `issues/0052-scan-then-sort-modal-flow.md`
- `issues/0053-file-a-book-without-dragging.md`
