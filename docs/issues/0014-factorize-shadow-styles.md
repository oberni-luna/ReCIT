Title: Fold the remaining hard-coded shadows into the design-system shadow enum
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Follow-up to the shadow abstraction introduced with the shelf label. That change created a
design-system shadow enum and view modifier but seeded it with a single case — the value
shared by the shelf label and the focus cell's cover art — and deliberately left the other
documented shadows as literals, to keep the label change reviewable.

Finish the job: give each remaining documented shadow a case on the enum and migrate every
call site to the modifier, so no shadow value is written as a literal in feature code.

The documented set covers the pressed-button shadow, the thumbnail shadow, the entity glow,
the painted-book shadow, the book-spine contact shadow and the lying-book shadow. Their
recorded values are the contract — this is a factorisation, not a redesign, and nothing
should change on screen.

Two things the design-system reference already warns about, which must survive the move:

- The book-spine shadow is far heavier than any interface shadow because it reads as
  **contact**, not elevation. It must not be normalised toward the ambient shadow.
- The lying-book shadow is the only one in the system with a non-zero horizontal offset —
  that offset is what sells the light direction, and it must be preserved.

Also note the open divergence that every shadow is pure black in both modes and so is
invisible against a dark background. This issue does not have to fix that, but consolidating
the values into one place is what would make fixing it a single edit later.

Update the design-system reference so each style's Swift symbol points at the enum case
rather than at a scattered literal, and drop the note about the pending migration.

## Acceptance criteria

- [ ] Every documented shadow style has a case on the design-system shadow enum.
- [ ] Every feature call site uses the modifier; no shadow literals remain outside the design system.
- [ ] Each shadow's offset, blur and colour are unchanged from the documented values.
- [ ] The book-spine contact shadow keeps its heavier value and is not normalised.
- [ ] The lying-book shadow keeps its horizontal offset.
- [ ] Nothing changes visually anywhere in the app.
- [ ] The design-system reference lists the enum case as each style's Swift symbol, and the pending-migration note is removed.

## Blocked by

- issues/0009-shelf-label-sticker.md — introduces the enum this issue extends.
