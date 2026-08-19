Title: Document the shelf label, the new shadow and the moved affordances
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Write up what shipped, in the places this project already keeps that record.

**Design-system reference.** Add the new shadow to the documented shadow-style table, with
its offset, blur, colour token and Swift call site, alongside the six that are already
listed. Add its colour token to the shadow token table. Add the label's paper and ink to
the `shelf/*` semantic table. Record the new shadow enum and its view modifier as the Swift
symbols, and note that the remaining five shadows are still literals pending migration.
Record, as a deliberate divergence rather than a bug, that the label's colours are
mode-independent while the app's background and foreground roles are not — the shelf
illustration has no dark variant, so an inverting label would put near-black paper on a
cream wash.

**Feature doc.** Add a new numbered feature document covering the label, the header's add
action, and the move of editing from the card to the detail navigation bar, following the
existing feature docs' shape. Note that it supersedes the card-level pencil affordance.

**Index.** Link the new feature doc from the "Shipped features" list — in **both** copies of
`CLAUDE.md`, the root one and the one inside the Xcode project folder, which the project's
own guidance says must be kept in sync.

Both `docs/` and its root-level duplicate are git-tracked and byte-identical, so every file
written under `docs/issues/`, `docs/prd/` or `docs/features/` needs its twin updated too.

Do not claim the Figma style landed unless 0012 actually completed; if it is still open, say
so.

## Acceptance criteria

- [ ] The new shadow appears in the design-system shadow-style table with offset, blur, colour token and Swift call site.
- [ ] Its colour token appears in the shadow token table.
- [ ] The label's paper and ink appear in the `shelf/*` semantic table.
- [ ] The shadow enum and view modifier are recorded as the Swift symbols, with the pending migration of the other five noted.
- [ ] The mode-independent label colours are recorded as a deliberate divergence with its reasoning.
- [ ] A new numbered feature doc describes the label, the header add action and the moved edit action.
- [ ] It notes that it supersedes the card-level pencil.
- [ ] Both copies of `CLAUDE.md` link the new feature doc from "Shipped features".
- [ ] `docs/` and its root-level duplicate are identical afterwards.
- [ ] The Figma status is reported honestly against 0012's actual outcome.

## Blocked by

- issues/0009-shelf-label-sticker.md
- issues/0011-empty-shelf-card.md
