Title: Onboarding — the bilan on a phone that cannot arrange books
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

The scan worked, so the bilan still confirms what it added — but on a phone that cannot run the
arrangement, the offer is replaced by the reason.

The bilan reproduces the auto-sort review screen's own pattern: when the entry point is
enabled, show `Ranger mes livres`; otherwise show the existing unavailability view, which
decides for itself whether a route to Settings belongs beside it. The escape hatch reads
`Continuer sans ranger`.

### No new entry-point case

The auto-sort entry-point type is exhaustive, and its unavailability view already words all
three reasons — including the ineligible device. Its cases are *shapes* derived from
availability, not places that consume them, so adding a "scan tally" case would be a category
error. The wording stays in exactly one file.

That gives the three treatments for free, and they must stay distinct:

| Reason | What the bilan shows |
|---|---|
| Apple Intelligence switched off | the reason, and a route to Settings |
| Model still downloading | the reason, described as temporary, no Settings route |
| Device ineligible | the reason, no control at all — the user can do nothing about it |

Availability is read fresh, and the model type is observable, so switching Apple Intelligence on
and coming back must not need a relaunch.

## Acceptance criteria

- [ ] The bilan reads auto-sort availability and shows either the CTA or the existing
      unavailability view — never both, never neither
- [ ] No case is added to the auto-sort entry-point type, and no unavailability wording is
      duplicated
- [ ] Apple Intelligence switched off: the reason is stated with a route to Settings
- [ ] Model downloading: the reason is stated as temporary, with no Settings route
- [ ] Ineligible device: the reason is stated with no actionable control
- [ ] The count and its title are unchanged in every unavailable case — the scan still happened
- [ ] The escape hatch reads `Continuer sans ranger` and leaves the session
- [ ] Enabling Apple Intelligence and returning to the app makes the CTA appear without a
      relaunch
- [ ] All copy comes from the existing unavailability view or the string catalogue

## Blocked by

- issues/0027-onboarding-scan-tally.md
