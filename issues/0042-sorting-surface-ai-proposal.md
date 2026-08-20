Title: The model becomes one change generator among others
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

`Proposer un rangement`, at the foot of the list, runs the on-device pipeline and pushes its
result onto the same stack as everything else. The proposal is then editable by dragging, and
`Annuler` discards it like any other pending work — which closes the gap PRD 0006 left open, where
a plan could only be accepted or refused whole.

The conversion from plan to changes is where **name reconciliation** happens: a proposed name
whose comparison key matches an existing étagère becomes a move *into* that étagère instead of a
creation. Auto-sort never saw the user's existing shelves; on this screen they are right there, so
asking for help must not duplicate them. The comparison reuses the auto-sort name key, already
written and tested. The prompt is left alone — it took five rounds to settle and is documented as
drifting whenever a constraint is added.

Availability stops being a wall and becomes a button. The existing entry-point rule keeps deciding
which of the three reasons is worth saying and whether a route to Settings helps — but it now
governs one button, and the rest of the screen works regardless. That is what makes the feature
degrade rather than disappear on a device that cannot run the model.

The proposal can be asked for again after sorting by hand.

## Acceptance criteria

- [ ] `Proposer un rangement` fills the stack, and the proposed étagères appear marked `Nouvelle`
- [ ] A proposal naming an étagère the user already has files books into it and creates nothing
- [ ] `Annuler` discards a proposal exactly as it discards hand-made changes
- [ ] A proposal can be requested again after manual sorting, and does not duplicate what is
      already filed
- [ ] On an ineligible device the button is absent and the rest of the screen works
- [ ] With Apple Intelligence switched off, the reason is stated and a route to Settings is offered
- [ ] While the model downloads, the button is inert and described as temporary
- [ ] Enabling Apple Intelligence and returning re-enables the button without relaunching
- [ ] Books never leave the device
- [ ] The plan-to-changes conversion, reconciliation included, is asserted without a store

## Blocked by

- issues/0041-sorting-surface-create-shelf-inline.md
