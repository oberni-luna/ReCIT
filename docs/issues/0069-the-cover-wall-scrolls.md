# Le mur défile

## Parent

`docs/prd/0011-welcome-cover-wall.md`

## What to build

Le mur se met en mouvement pendant qu'on lit : quatre colonnes, les impaires vers le bas, les
paires vers le haut, à des vitesses légèrement différentes (~10 à 16 pt/s). Le déplacement est
continu et sans couture — au franchissement d'une période, la colonne se réenroule sans saut
visible.

Le défilement est piloté par un `TimelineView(.animation)` qui calcule chaque décalage depuis la
date, et non par une animation `repeatForever` : il n'y a alors rien à redémarrer au retour de
veille, rien à recoller après une rotation ou un changement de taille de texte.

Trois interrupteurs l'arrêtent, en laissant le mur composé mais immobile : « Réduire les
animations », le mode économie d'énergie, et le fait que l'écran ne soit plus visible (navigation
vers un formulaire, passage en arrière-plan).

## Acceptance criteria

- [ ] Les colonnes défilent en continu, alternativement vers le bas et vers le haut, à des
      vitesses distinctes et lentes.
- [ ] Aucune couture visible : le décalage bouclé de `CoverWallGeometry` est continu au passage
      d'une période, et le test le prouve numériquement.
- [ ] `accessibilityReduceMotion` actif → mur figé, toujours composé.
- [ ] Mode économie d'énergie actif → mur figé ; le passage du mode pendant que l'écran est ouvert
      est pris en compte (notification de changement observée), sans redémarrage de l'écran.
- [ ] L'app en arrière-plan, ou l'accueil quitté pour un formulaire, arrête le mouvement ; le
      retour ne produit ni saut ni ressaut.
- [ ] Tests `CoverWallGeometry` : continuité au franchissement de période pour chaque colonne,
      monotonie du décalage entre deux instants, directions alternées, et l'invariance du rendu
      quand la vitesse vaut zéro (mur figé identique au mur immobile de l'issue 0068).
- [ ] Le projet compile et la cible de test passe sur `iPhone 17`.

## Blocked by

- `docs/issues/0068-painted-cover-wall-behind-the-welcome-screen.md`
