# Assets

Aucun export nécessaire.

L'illustration des deux plein-écrans est la vraie étagère du code (`ShelfPlank` est le PNG réduit du dépôt ;
dans Figma le wash est approximé par une ellipse floutée, le vrai `ShelfWash` faisant 1 Mo — voir
`docs/design-system/figma-library.md`).

- **C1** : planche nue. Aucun livre, donc aucun asset, aucune donnée factice.
- **C2** : les vraies couvertures des cinq derniers livres non rangés, lues par `@Query` et chargées par
  `CachedAsyncImage` comme partout ailleurs. Le placeholder parchemin de `ShelfCoverView` couvre le temps de
  chargement — et il vaut la peine de vérifier ce que donne l'animation quand une couverture arrive **après**
  que le livre s'est posé.

En mode sombre, le wash reste un halo clair sur fond noir (visible sur `87:3011`). C'est le comportement
actuel du design system, pas un défaut de ces écrans, mais c'est plus voyant sur un plein-écran que sur une
carte de carrousel.
