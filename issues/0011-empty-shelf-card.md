Title: Empty shelf replaces the trailing create card
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Retire the create card from the tail of the carousel and repurpose it as the zero-étagères
empty state, so the carousel ends on the user's last real shelf.

The card now renders **only** when the user has no étagères. Drop its large "+" glyph — a
UI symbol floating inside a painted illustration, and redundant now that the header carries
the create action. In its place, put a label on the plank in exactly the shelf label's
style, reading **"Todo : ranger mes livres dans une étagère"**, tilted by the same
text-derived rule, its text centred and allowed to wrap onto two lines.

No chevron on this one: the card opens a sheet rather than pushing a screen, and a chevron
would promise navigation that doesn't happen. Centring also reads as off-centre next to a
trailing glyph.

The two-line label simply extends further down from the same top-anchored plank overlap, so
the inset established for the shelf label stays valid unchanged.

Tapping anywhere on the card opens the create form. The card's existing plank-alignment
metrics are unchanged, so an empty shelf lines up with a real one.

Rename the type and its file to reflect that it is now an empty state rather than a create
card.

## Acceptance criteria

- [ ] A user with at least one étagère sees the carousel end on their last shelf — no trailing card.
- [ ] A user with no étagères sees exactly one empty shelf card.
- [ ] That card carries a label reading "Todo : ranger mes livres dans une étagère".
- [ ] The label uses the shelf label's paper, radius, shadow, padding and text-derived tilt.
- [ ] Its text is centred and wraps onto at most two lines.
- [ ] It carries no chevron.
- [ ] The large "+" glyph is gone.
- [ ] Tapping anywhere on the card opens the create form. *(Amended by issue 0025 — see
  Amendments below: the whole card now starts the auto-sort flow, and the create form is
  what that tap falls back to where Apple Intelligence cannot run.)*
- [ ] Creating the first étagère replaces the empty card with the real shelf, with no manual refresh.
- [ ] The empty card's plank aligns with a real shelf card's plank.
- [ ] The type and file are renamed away from "create card".

## Blocked by

- issues/0009-shelf-label-sticker.md — reuses the shared label view and the tilt function.
- issues/0010-ajouter-button-section-header.md — the create card is removed here, so the header action must exist first.

## Amendments

**Amended by `issues/0025-auto-sort-entry-points-availability.md` (PRD 0006), shipped after
this one.** The card's tap *target* is unchanged — the whole card, never a second hit zone —
but where that tap leads now depends on what the device can do. It starts the automatic
shelving flow, and opens the create form only where Apple Intelligence cannot run, since the
flow could never work there and this card is the empty state and so can never be a dead end.
The manual create path is not lost: the section header's "Ajouter" action covers it, which is
part of why the create action moved there in the first place.

Everything else recorded here stands as shipped: the label and its wording, the retired "+"
glyph, the absent chevron, the two-line centred text, the plank alignment and the rename.
