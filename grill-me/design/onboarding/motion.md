# Mouvement — l'étagère se remplit

Sur `C2 · Bilan du scan`, les livres ne sont pas là au chargement : ils **se posent un par un** sur la
planche, de haut en bas. Ce sont les vraies couvertures — les cinq derniers livres non rangés, lus par
`@Query` — donc le mouvement est un accusé de réception, pas une décoration.

**C1 n'a pas d'animation** : sa planche est nue, parce que l'inventaire est vide. Y peindre des dos inventés
pour avoir quelque chose à animer aurait fabriqué une étagère qui ressemble à des données inexistantes.

## Paramètres

| Propriété | Valeur |
|---|---|
| Opacité | `0` → `1` |
| Décalage vertical | `-32` → `0` pt (le livre descend sur la planche) |
| Courbe | `.easeOut` |
| Durée par livre | `0.32 s` |
| Décalage entre deux livres | `0.08 s` |
| Ordre | gauche → droite, l'ordre de dessin de `ShelfBooksLayout` |
| Total (6 livres) | ≈ `0.72 s` |
| Répétition | aucune. Une fois par apparition de l'écran, jamais en boucle |

`easeOut` plutôt qu'un `spring` : un ressort ferait rebondir un livre posé sur une planche, ce qui lit comme
un objet qui tombe et non comme un objet qu'on range. Le vocabulaire du design system est déjà
`easeOut(0.2)` pour les appuis (`LargeButtonStyle.swift:78`) et le ressort est réservé à la prise en main
d'un livre (`ShelfRowView.swift:201`).

## Accessibilité

`@Environment(\.accessibilityReduceMotion)` : quand il est vrai, **le décalage disparaît** et il ne reste
que le fondu, même durée, même échelonnement. On ne supprime pas l'échelonnement — c'est lui qui porte le
sens (« un par un »), et un fondu n'est pas un mouvement.

## Où ça vit

Pas dans `ShelfBooksView` : cette vue est pilotée par les données et se redessine à chaque scroll du
carrousel ; y mettre une animation d'apparition ferait re-tomber les livres de chaque étagère à chaque
passage. L'animation appartient à la vue de l'illustration du bilan, qui dessine la planche et pose dessus
les livres qu'elle reçoit.

L'illustration doit donc être une **composition de vues**, pas une image plate : une planche, plus des
livres animables un par un. Un asset unique aplati rendrait l'animation impossible.
