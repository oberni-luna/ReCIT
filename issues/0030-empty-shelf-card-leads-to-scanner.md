Title: The empty-shelf card leads to the scanner while the inventory is empty
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

The note resting on the empty plank stops being one fixed errand. It says what the next useful
thing is, and it opens that thing:

| State | Note | Destination |
|---|---|---|
| Inventory empty | `☐ Scanner mes livres` | the batch scanner |
| Books on no étagère | `☐ Ranger mes livres` | the auto-sort flow |

This is what keeps the accueil's `Plus tard` from being a dead end: the invitation comes back
down onto the card, in the one place the user is already looking.

### This revisits a decision, and has to say so

PRD 0006 deliberately removed a second destination from this card, and the reasoning is written
out at length where the tap is handled. Rewrite that reasoning — do not quietly reverse it.

What 0006 removed was a **silent** substitution keyed on hardware: a note reading
`Ranger mes livres` that opened a create-shelf form on an ineligible device, where the user
could not see why. Here the note changes with the state, so the affordance is stated before it
is used. The rule that survives is the one that mattered all along: a card must never open
something other than what its label promises.

The manual route is untouched — the section header's `Ajouter` still creates an étagère by hand.

### Scope

The whole card stays one hit target, painted or not. No second hit zone inside the illustration:
that is the problem the card-level pencil's removal solved.

## Acceptance criteria

- [ ] With an empty inventory, the note reads `Scanner mes livres` and the card opens the batch
      scanner
- [ ] With books on no étagère, the note reads `Ranger mes livres` and the card opens the
      auto-sort flow, as today
- [ ] The label and the destination cannot disagree — they are decided in one place
- [ ] The whole card remains a single hit target
- [ ] The section header's `Ajouter` still creates an étagère by hand
- [ ] The documentation where the tap is handled explains the state-dependent destination and
      why it is not the hardware-dependent substitution PRD 0006 removed
- [ ] Copy lives in the string catalogue
- [ ] Renders in light and dark

## Blocked by

None - can start immediately
