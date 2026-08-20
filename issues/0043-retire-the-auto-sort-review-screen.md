Title: Retire the auto-sort review screen and its write path
Labels: needs-triage
Type: HITL

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

The demolition. Two screens have been proposing étagères since the previous slice; this one leaves
the app with a single sorting surface and a single write path.

- The existing entry points — the settings row and the empty-shelf étagère card — now open the
  sorting surface.
- The auto-sort orchestration model **stops writing**: its apply, its ledger and its
  applying/applied phases go. It keeps the pure pipeline and the conversion to changes.
- The old review screen and the pieces only it used are deleted.
- The apply-ledger test suite moves with the module rather than being rewritten.

Review needed before merging, which is why this is HITL: it removes a shipped feature's screen and
re-points two entry points that other work has been built on. Read the empty-shelf card's decision
first — it deliberately leads into the flow on every device, and the flow states the reason, which
must stay true of the surface it now opens.

Nothing here changes behaviour the user can name: the same entry points, the same words on arrival,
one screen instead of two.

## Acceptance criteria

- [ ] The settings entry point and the empty-shelf card open the sorting surface
- [ ] On an ineligible device the empty-shelf card still leads into the flow, and the reason is
      still stated — as a button state now, not a wall
- [ ] The auto-sort model no longer writes: no apply, no ledger, no applying/applied phases
- [ ] The old review screen and its now-unused pieces are deleted, and nothing references them
- [ ] The apply-ledger suite lives with the ledger and still passes
- [ ] The whole test target passes
- [ ] `docs/features/0008-ai-auto-sort.md` records that the review-and-apply flow was replaced,
      and by what
- [ ] `docs/design-system/figma-library.md` marks the superseded frames as such rather than
      deleting them

## Blocked by

- issues/0042-sorting-surface-ai-proposal.md
