Title: Shelf name becomes a tilted paper label stuck to the plank
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Replace the étagère's small grey caption and its pencil with a **label**: a white paper tag
with rounded corners and a soft shadow, stuck onto the plank's bottom edge, tilted very
slightly, carrying the shelf's name at reading size with a trailing chevron. Pressing
anywhere on it opens that shelf's book list.

**Tilt.** A pure function of the label's own text — text in, an angle within about a degree
either way out. Derived from the text rather than from the shelf, so the same rule serves
the empty-state label later, which has no shelf behind it. Nothing is persisted and no
schema changes: the angle is recomputed from text already in the model. The hash must fold
over Unicode scalars, not ASCII bytes — French shelf names are full of accented characters
and an ASCII-only fold collapses them to one value. It must not use process-seeded hashing,
whose failure mode (a different angle every launch) is invisible within a single run.
Accepted consequence: renaming an étagère re-rolls its tilt.

**Placement.** The label overlaps the plank's bottom edge by a fixed inset taken from the
design. It stays inside the card's vertical stack with a negative top padding rather than
becoming a true overlay, so the stack reserves its height automatically at any Dynamic Type
size, planks stay aligned card-to-card, and the horizontal scroll view cannot clip its lower
half. ADR 0003 records that self-measuring shelf cards caused a collection-view update loop;
reserving height in the stack keeps the card's size deterministic. Anchor the overlap from
the label's *top* so a taller label extends downward and the inset stays valid.

**Width.** Content-driven with a ceiling of the card width minus the books' horizontal
margins. Long names truncate with an ellipsis; the chevron sits outside the truncating text
so it never disappears.

**Colours.** The label's paper and ink are new mode-independent entries in the existing
`shelf/*` palette family — deliberately not the app's background/foreground tokens, which
invert in dark mode. The shelf illustration is a single universal asset with no dark
variant, so an inverting label would put near-black paper on a cream wash. Same reasoning
that already keeps the spine contact shadow at 45% rather than normalising it.

**Shadow.** Introduce a shadow abstraction in the design system — an enum plus a view
modifier — seeded with the single value currently hard-coded on the focus cell's cover art.
Migrate that call site to it and use it for the label, so the two cannot drift.

**Sharing.** The label is one reusable view parameterised by text, chevron visibility, line
limit and text alignment, so the empty-state label can reuse it without duplication.

**Navigation.** Use a navigation link carrying the shelf destination value, replacing the
manual path append, matching how the "Tous les livres" list already navigates. Draw the
chevron explicitly — a navigation link supplies no disclosure indicator outside a list.

**Removal.** The pencil, its edit state and its sheet leave the card entirely; editing now
lives in the detail navigation bar.

## Acceptance criteria

- [ ] The shelf name renders on a white rounded tag with a shadow, overlapping the plank's bottom edge.
- [ ] The name uses the larger serif content style, not the small caption style.
- [ ] A chevron sits at the trailing edge of the label.
- [ ] Pressing anywhere on the label — text, chevron or padding — pushes that shelf's book list.
- [ ] Each label is tilted within about a degree either way.
- [ ] The same shelf name always produces the same angle, across repeated renders, across carousel recycling, and across app launches.
- [ ] Accented French names produce varied angles rather than collapsing to one.
- [ ] A long shelf name truncates with an ellipsis, the label never exceeds the card width minus the books' margins, and the chevron stays visible.
- [ ] The label keeps dark ink on light paper in dark mode.
- [ ] The label dims with the rest of the card under the focus veil during a press.
- [ ] The pencil, its state and its sheet are gone from the shelf card.
- [ ] The focus cell's cover art uses the new shadow modifier and looks unchanged.
- [ ] The label view is shared, parameterised for text, chevron, line limit and alignment.
- [ ] Navigation uses a navigation link with the shelf destination value, not a manual path append.
- [ ] No SwiftData schema change and no migration.
- [ ] Unit tests cover the tilt function: range, stability across repeated calls, accent handling, and spread across a set of realistic étagère names.
- [ ] Planks stay aligned across carousel cards at default and at large Dynamic Type sizes.

## Blocked by

- issues/0008-modifier-action-shelf-detail.md — the pencil is removed here, so the detail-screen edit path must exist first.
