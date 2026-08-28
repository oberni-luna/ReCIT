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

## This contradicts issue 0052 on two points — resolve before building

`issues/0052-scan-then-sort-modal-flow.md` specifies the same stretch of the flow and says:

1. *« The bilan doubles as the invitation to file; no screen is added between it and the
   sorting screen. »* — this issue adds exactly one screen there, the loading step, and that is
   what was asked for out loud.
2. *« The sorting screen offers no way back to the bilan »* — a pushed loading screen sits in
   that stack and inherits the question of what its back gesture does.

They cannot both ship as written. Either the loading step becomes the sorting surface's own
loading state — which is `0036`'s territory, and one destination rather than two — or `0052`'s
criterion is amended to allow it. **Decide it in writing on one of the two issues before either
is implemented**; do not let the second implementer discover the contradiction.

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
- [ ] The contradiction with `0052` is settled in writing on one of the two issues

## Blocked by

- The sorting surface itself must exist and accept a proposal — `issues/0046-grid-sorting-surface-read-only.md`, `issues/0051-proposal-button-in-the-action-bar.md` and `issues/0052-scan-then-sort-modal-flow.md`.
