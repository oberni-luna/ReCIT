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

## What was generated — 2026-08-23

Twelve frames in the `Ranger mes livres` section (page `Tokens`), in a row at `y = 3283`
starting at `x = 1085`, each cloned from the nominal frame so they carry the same components,
the same instances and the same bound variables:

| Frame | Node | What it shows |
|---|---|---|
| Ouverture · Light | `164:2` | the grid replaced by « Synchronisation de votre bibliothèque… », the carousel's height reserved and empty, no recap |
| Grille vide · Light | `164:58` | the « + Nouvelle étagère » tile alone — dashed, tinted, glyph above the label |
| Tout rangé · Light | `164:114` | « Livres à ranger · 0 », the carousel replaced by one line, the panel shrunk |
| Carte à un livre · Light | `164:170` | one cover face-on, « · 1 » |
| Carte à deux livres · Light | `164:226` | the fan's first two positions, « · 2 » |
| Étagère vide · Light | `164:282` | a cover-shaped dashed hole — the normal state of a draft |
| Survol de la cible · Light | `164:5945` | the target card with its accent border, and the cover travelling under the finger |
| Enregistrement en cours · Light | `164:6001` | library at 80 %, a spinner on the étagère in flight |
| Échec partiel · Light | `164:6057` | the warning badge on the étagère that broke, and the three-part report — the panel grown upward, as it does on device |
| Pastilles · Light | `164:6113` | « Nouvelle » and « Modifiée » as glyphless `Tag` instances |
| Détail étagère · Light | `164:6169` | the pushed screen, which had no mockup at all: three books in pile order, the swipe revealed, no genre line and no grip |
| Dark | `164:6225` | the nominal state with the `Color` collection's Dark mode set explicitly, the way the file's existing dark frames declare themselves |

The three drag frames are renamed `Superseded (PRD 0009) · …` rather than deleted.

Divergences recorded in `docs/design-system/figma-library.md` as **D45–D48**: the étagère
gutter (12 in Figma, 16 in code), the nav bar's `+` replaced by the grid tile, the missing
Alegreya token at card-title size, and the generation itself.

**Owner review is still owed.** Two known roughnesses to look at: the travelling cover on the
hover frame overlaps the second row of cards, and the spinner on the saving frame sits inside
the card's auto-layout rather than over its art.

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
