Title: The bilan leads into the sorting surface, with or without a proposal
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0009-grid-shelf-sorting.md · Feature: docs/features/0007-batch-scanner.md

## What to build

The bilan's ending currently depends on whether the phone can run the arrangement: a CTA into
the auto-sort review screen, or a reason and no CTA at all. Both change.

| Apple Intelligence | CTA | What happens |
|---|---|---|
| available | **« Rangement automatique »** | pushes a loading screen while the model works, which is replaced by the sorting surface carrying the proposal — **not yet applied** |
| unavailable | **« Ranger mes livres »** | pushes the sorting surface directly, with no proposal: every scanned book sits in « À ranger » and the user files them by hand |

The point is that a phone that cannot run the model is no longer a dead end. It loses the
proposal, not the ability to sort — which is the whole reason the sorting surface exists.

Reported from a device (an iPhone 14 Pro, ineligible) where the bilan ended on
« Le rangement automatique n'est pas disponible sur cet appareil » and « Continuer sans
ranger », leaving the user with two freshly scanned books and nowhere to put them.

## Settled: 0052's rule was withdrawn, not worked around

`issues/0052-scan-then-sort-modal-flow.md` said no screen may come between the bilan and the
sorting screen. **That rule is withdrawn**, on a decision taken 2026-08-28, and the withdrawal is
recorded in an amendment on that issue rather than by quietly editing it away. The loading screen
is in scope.

The second half of the tension is resolved by construction: the loading screen is **replaced by**
the sorting surface rather than pushed under it, so 0052's other rule — the surface has no back
to the bilan, only an explicit close — survives untouched. Backing out of the loading screen
itself returns to the bilan and means "never mind": nothing has been computed or written yet.

Division of labour between the two issues: 0052 owns the container, the stack and the close;
this one owns what the bilan offers and what happens behind each CTA.

## The unavailability reason does not disappear

Where the model cannot run, the reason is still stated — it is the honest half of
features/0008 and the wording already exists in `AutoSortUnavailableView`. What changes is that
it stops being the *end* of the screen: the reason is said, and « Ranger mes livres » is offered
underneath it.

## Acceptance criteria

- [ ] On an eligible device the bilan offers « Rangement automatique », which pushes a loading
      screen and then the sorting surface carrying the proposal
- [ ] The proposal arrives **unapplied**: nothing is created or written until the user says so
      on the sorting surface
- [ ] On an ineligible device, or with Apple Intelligence off, or while the model downloads, the
      bilan offers « Ranger mes livres » straight into the sorting surface with no proposal
- [ ] The reason is still stated in those three cases, above the CTA rather than instead of it
- [ ] A model failure mid-load does not strand the user on the loading screen: it lands on the
      sorting surface with no proposal and says the proposal failed
- [ ] Availability is read fresh, so switching Apple Intelligence on and returning changes which
      CTA is offered without a relaunch
- [ ] Both labels live in `Localizable.xcstrings`
- [ ] The loading screen is replaced by the sorting surface, never left underneath it, so no back
      chevron to the bilan appears
- [ ] Backing out of the loading screen returns to the bilan with nothing computed or written

## Blocked by

None - can start immediately.

The three issues this once waited on have all shipped: `0046` (the grid surface), `0051` (the
proposal button) and `0052` (the one modal flow, `5d83959`). That changes the work rather than
removing it: `0052` was **built with** the withdrawn no-screen rule in force, so this issue now
edits a shipped flow instead of completing a missing one. Read `Features/Sorting/SortFlowView`
and `SortFlowRoute` before touching anything — the route enum is where the loading step belongs,
and the flow already owns its stack and its close.
