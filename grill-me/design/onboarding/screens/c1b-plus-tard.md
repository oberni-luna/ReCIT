# C1b · Après « Plus tard » — `87:2880`

Clone de l'inventaire vide (`Étagères · Empty`, `70:2460`) : nav `Inventaire`, champ de recherche,
en-tête `Étagères`, carte d'étagère vide, en-tête « Tous les livres · 0 », texte `inventory.empty`
(« Oh, c'est vide ici »), barre d'onglets.

La seule différence avec l'écran d'aujourd'hui : **le mot papier posé sur la planche**.

| Élément | Détail |
|---|---|
| mot papier | `shelf/label/paper`, encre `shelf/label/ink`, style d'effet `Shadow/Light`, rotation −1,5° |
| contenu | en-tête « Todo » (`footnote200Bold`) + une ligne « ☐ Scanner mes livres » (`footnote200`) + chevron |
| légende sous la planche | « Scanner mes livres » (prop `Name#34:3` de `Shelf Empty Card`) |

Aujourd'hui le mot dit « Todo / ☐ Ranger mes livres » et la carte mène au rangement automatique
(features/0008). Ici il dit « Scanner » **parce que l'inventaire est vide** : il n'y a rien à ranger.

## Conséquence pour le code

`ShelfEmptyStateView` porte un libellé fixe. Il devient conditionnel, et la destination du tap avec lui :
inventaire vide → scanner ; livres non rangés → rangement automatique. C'est un point à grillier : la carte
d'étagère vide a **deux** destinations selon l'état de l'inventaire.

Pas de variante sombre maquettée.
