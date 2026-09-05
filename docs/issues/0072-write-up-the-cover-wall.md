# L'écrit : ce que le mur est devenu

## Parent

`docs/prd/0011-welcome-cover-wall.md`

## What to build

La fonctionnalité livrée est écrite là où le dépôt écrit ce qu'une fonctionnalité **est devenue** :
un document dans `docs/features/`, le PRD supprimé (git le garde), et la ligne de passe de la
bibliothèque Figma mise à jour pour dire que `B3` est la maquette retenue et ce qui a divergé entre
la maquette et le code.

## Acceptance criteria

- [ ] `docs/features/0013-welcome-cover-wall.md` : ce que fait l'écran, la surface technique
      (modules, endpoint, cache, politique d'animation), les décisions écartées et pourquoi, et les
      pièges à connaître avant d'y toucher.
- [ ] La table « Shipped features » de `CLAUDE.md` gagne sa ligne.
- [ ] `docs/prd/0011-welcome-cover-wall.md` est supprimé, conformément à `docs/prd/README.md`.
- [ ] `docs/design-system/figma-library.md` : la passe du jour dit que `B3` (`265:7532`) est la
      maquette retenue, et liste les divergences code ↔ Figma constatées à l'implémentation
      (nombre de colonnes, taille de cellule, vitesses, densité du voile).
- [ ] Aucun code touché dans cette issue.

## Blocked by

- `docs/issues/0069-the-cover-wall-scrolls.md`
- `docs/issues/0071-the-cover-wall-remembers.md`
