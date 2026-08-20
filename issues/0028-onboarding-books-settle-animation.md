Title: Onboarding — the scanned books settle onto the plank one by one
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

The bilan's plank stops being bare: it carries the user's **real covers**, and they arrive one
at a time.

This is the payoff of the whole sequence. The accueil promises with words over an empty plank;
the bilan pays with the books the user just scanned, settling into place.

### Where the covers come from

Not carried out of the scanner. The bilan reads the most recently created unshelved books
straight from the store, newest first, and paints those — invariant 1 of ADR 0001: views render
from `@Query`. The query can pick up a book added before this session; harmless, it is recent
and unshelved too.

Covers load through the same cached-image path as everywhere else, so the parchment placeholder
covers the wait. Worth checking what the animation looks like when a cover arrives **after** its
book has settled.

### The arrival

Per book: opacity `0 → 1`, vertical offset `−32 → 0` points, ease-out over `0.32 s`, staggered
`0.08 s` apart, left to right, once per appearance of the screen. Roughly `0.72 s` end to end
for six books.

Ease-out, not a spring: a book set down on a plank does not bounce, and the design system
already reserves springs for picking a book *up*.

### Reduce Motion

The offset drops, the fade and the stagger stay. The stagger carries the meaning — one book at a
time — and a fade is not a movement.

### Where it lives

In the bilan's own illustration view, **not** in the shelf's book renderer. That one is
data-driven and redraws on every carousel scroll; an appearance animation there would drop the
books of every étagère each time one scrolled past.

The illustration is therefore a composition of views — a plank plus animatable books — never a
flattened image.

## Acceptance criteria

- [ ] The bilan's plank carries the most recently created unshelved books, read by `@Query`,
      newest first
- [ ] Each book fades in from opacity 0 and slides down 32 points into place, ease-out over
      0.32 s, staggered 0.08 s apart, left to right
- [ ] The animation runs once per appearance and never loops
- [ ] With Reduce Motion on, the offset is gone while the fade and the stagger remain
- [ ] The shelf carousel is untouched: scrolling past an étagère does not animate its books
- [ ] A cover that finishes loading after its book has settled does not restart the animation
      or jump the layout
- [ ] The illustration remains a composition of views, with no flattened image asset introduced
- [ ] Renders correctly in light and dark

## Blocked by

- issues/0027-onboarding-scan-tally.md
