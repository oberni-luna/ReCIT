## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

The states the mockup does not draw, generated into the Figma file `Nouveau récits` under the
`Ranger mes livres` section, from the decisions in the PRD — then reviewed and corrected by
the owner. Feature 0009 did this same work first, for the same reason: a state nobody drew is
a state invented at implementation time and argued about in review.

Twelve frames, all light unless stated:

1. Opening sync — grid replaced by a progress indicator, bottom panel in place but inert,
   carousel height reserved.
2. Empty grid — the « + Nouvelle étagère » tile alone.
3. « Tout est rangé » — carousel replaced by one centred line, panel shrunk by the
   carousel's height.
4. Étagère card with one book — the cover alone.
5. Étagère card with two books.
6. Étagère card with none — the empty frame a freshly created draft shows.
7. A hovered drop target — card at scale 1,03 with its accent border, mid-drag, cover under
   the finger.
8. Apply in progress — grid and carousel at 80 %, the written étagères breathing, a spinner
   on the one in flight.
9. A failed étagère — its warning badge, plus the three-part stopped report in the footer
   slot (which grows and pushes the grid up).
10. A status pill on a card — « Nouvelle » and « Modifiée ».
11. The pushed étagère detail screen — no mockup exists at all: rows in pile order, the
    swipe revealed, the empty state.
12. The dark twin of the nominal state.

Existing components are reused rather than redrawn: the section header, the bottom action
bar, the `Livre` instance, and the design system's variables and text styles. Divergences
between code and Figma are recorded in `docs/design-system/figma-library.md`, not silently
fixed — code is the source of truth.

Two divergences are already known and must be recorded rather than drawn away: the étagère
gutter is 16 pt in code against the mockup's 12 pt, and the nav bar's « + » is gone, replaced
by the grid's tile.

## Acceptance criteria

- [ ] The twelve frames exist under the `Ranger mes livres` section, named consistently with
      the existing frames (`… · Light` / `… · Dark`).
- [ ] Each frame reuses existing components and bound variables — no hardcoded colours, no
      detached instances.
- [ ] The three superseded drag frames from feature 0009 are marked superseded, not deleted.
- [ ] The two known code/Figma divergences are recorded in
      `docs/design-system/figma-library.md`.
- [ ] The owner has reviewed the frames and their corrections are applied.

## Blocked by

None - can start immediately.
