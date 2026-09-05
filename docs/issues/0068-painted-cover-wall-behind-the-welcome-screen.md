# Le mur peint, immobile, derrière l'accueil

## Parent

`docs/prd/0011-welcome-cover-wall.md`

## What to build

L'écran d'accueil s'ouvre sur un mur de couvertures **peintes** qui remplit l'écran, sous un voile
vert dégradé, avec le texte en crème. Aucun réseau, aucun asset : les couvertures sont générées en
code dans la grammaire des étagères (aplats `color/green/*`, `color/red/800`, `color/yellow/400`,
parchemin, bandeau et lignes de titre).

Le mur est **immobile** dans cette tranche — le défilement arrive avec l'issue suivante. Ce qui est
livré ici, c'est la géométrie (module pur et testé), le rendu, et l'accueil repeint.

`CoverWallView` prend ses couvertures, sa taille de cellule et son nombre de colonnes en
paramètres : il doit pouvoir resservir à l'état « inventaire vide » plus tard, sans réécriture.

Les trois arrangements `ViewThatFits` de `WelcomeView` sont **conservés tels quels** ; le mur
devient leur fond, sous le voile.

## Acceptance criteria

- [ ] `CoverWallGeometry`, module pur (pas de SwiftUI, pas de réseau) : depuis une taille
      disponible, une taille de couverture, une gouttière, un nombre de colonnes, un nombre
      d'images et un temps écoulé, il donne pour chaque colonne son décalage vertical, sa
      direction et sa phase initiale, et pour chaque case l'index d'image à y mettre.
- [ ] Le mur couvre tout l'écran, y compris sous la status bar et le home indicator, sans case
      vide, et rend assez de contenu par colonne pour que la boucle de l'issue suivante n'ait pas
      de couture.
- [ ] Deux colonnes voisines n'ont pas la même phase initiale : aucun damier aligné.
- [ ] `PaintedCoverView` rend une couverture peinte déterministe pour un index donné : teinte
      prise dans la palette, bandeau, deux lignes de titre, coin arrondi de 2 pt, ombre
      `Shadow/Painted Book` (le littéral utilisé par les étagères).
- [ ] `WelcomeView` : voile vert dégradé par-dessus le mur, nom et accroche en crème, trois lignes
      d'usage lisibles, boutons intacts. L'écran est sombre **dans les deux modes système**, status
      bar et home indicator en apparence sombre.
- [ ] Le mur est décoratif : masqué au lecteur d'écran (VoiceOver passe directement au contenu) et
      insensible au toucher, pour qu'il ne puisse jamais avaler un appui destiné à un bouton.

      **Corrigé en cours de route** : cette issue demandait aussi un identifiant
      `e2e.welcome.coverWall`. Les deux s'excluent — un nœud masqué au lecteur d'écran sort de
      l'arbre d'accessibilité, et XCUITest ne voit que cet arbre. L'accessibilité gagne : le
      scénario end-to-end prouve déjà l'écran d'accueil par `e2e.welcome.signIn`, qui existe.
- [ ] Aux tailles d'accessibilité, les trois arrangements existants continuent de fonctionner :
      rien n'est tronqué, les deux boutons restent atteignables.
- [ ] Tests `CoverWallGeometry` : couverture complète de l'écran, phases distinctes, directions
      alternées, et les cas limites — zéro image, une seule image, moins d'images que de cases.
- [ ] Le projet compile et la cible de test passe sur `iPhone 17`.

## Blocked by

None - can start immediately
