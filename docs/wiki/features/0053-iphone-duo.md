# Ex-libris sur iPhone Duo

Livré le 2026-10-27, sur `main`, sans PRD ni issues. Une revue des écrans sur le simulateur iPhone Duo (Xcode 27.1,
iOS 27.1) a relevé sept points. Le propriétaire a tranché chacun dans un artefact de décision : six à faire, un refusé.
Une seconde passe, sur le Duo déplié, a ajouté un huitième point : les titres des formulaires.

## L'appareil

Le Duo a deux écrans :

| État | Taille |
|---|---|
| Plié | 466 × 678 pt |
| Déplié, portrait | 669 × 951 pt |
| Déplié, paysage | 951 × 669 pt |

Plié, ou déplié en paysage, iOS range l'heure, les boutons de la barre de navigation et la barre d'onglets dans une
colonne verticale sur le bord droit. Notre contenu se centre donc dans la largeur qui reste. Déplié en portrait, la
mise en page redevient celle d'un iPhone.

Le simulateur demande le runtime iOS 27.1 (`xcodebuild -downloadPlatform iOS`). Xcode 27.1 n'a plus de Simulator.app :
la fenêtre des simulateurs s'appelle `DeviceHub.app`, dans `Xcode.app/Contents/Applications/`. Seul DeviceHub sait
plier et déplier l'appareil ; `simctl` ne le sait pas.

## Ce qui a changé

La règle commune : **aucun iPhone ne change**. Chaque plafond est placé au-dessus de la valeur qu'atteint le plus grand
iPhone (430 pt). Il ne joue donc que sur un écran plus large.

**Les couvertures gardent leur format 2:3** (`SortGridMetrics`). Les piles de « Ranger mes livres », son panneau
« À ranger » et « Chez mes amis » de la Recherche prenaient leur largeur dans la colonne, mais leur hauteur était
plafonnée (`artHeight` 106 pt, `bookArtHeight` 100 pt). Sur 669 pt, les couvertures devenaient plus larges que
hautes. Désormais, une couverture trop haute pour sa zone se rétrécit au lieu de s'aplatir :
`pileCoverSize(width:isSingleCover:)` calcule la plus grande largeur qui tient, inclinaison comprise, et la nouvelle
`bookCoverSize(width:)` fait de même pour une carte de livre. Ça corrige au passage les piles déjà écrasées sur iPhone
dans la grille à deux colonnes, celle d'une bibliothèque de deux étagères ou moins.

**Des colonnes en plus plutôt que des cartes plus larges**. Une carte d'étagère ne dépasse pas 200 pt
(`maxShelfCardWidth`), une carte de livre 120 pt (`maxBookCardWidth`). Au-delà, la grille ajoute des colonnes
(`shelfColumnCount(forShelfCount:)`) et le carrousel ajoute des cartes avant celle qui dépasse (`bookColumnCount`).
Déplié en portrait, ça donne 4 colonnes d'étagères et 5 livres visibles ; en paysage, 4 étagères et 8 livres. Une
petite bibliothèque garde ses deux colonnes, avec des cartes plafonnées.

**Le carrousel d'étagères est plafonné à 370 pt** (`ShelfCardMetrics.carouselCardWidth(containerWidth:)`), la largeur
que donnent 86 % de 430 pt. Avant, une étagère prenait environ 60 % de l'écran déplié en portrait ; en paysage, une
étagère d'un seul livre montrait une couverture d'environ 400 pt de haut. Le carrousel des étagères d'un ami
(`UserShelvesSection`) suit la même règle.

**Une largeur de lecture de 540 pt**, nouvelle valeur du design system (`DesignSystem.ReadableWidth`), avec deux
modificateurs dans `View+readableWidth.swift` :

- `readableWidth()` limite un bloc et le centre. Il s'applique à l'accueil (texte et boutons, le mur restant en
  pleine largeur), à la connexion, à la création de compte et au mot de passe oublié (le formulaire et la barre de
  bouton du bas) ;
- `readableContentMargins()` élargit les marges horizontales d'une `List` ou d'un `Form`. Les lignes se resserrent,
  mais le fond va toujours jusqu'aux bords de l'écran. Il s'applique à la fiche livre, à la fiche auteur, à la liste
  des éditions, et à tous les formulaires, puisque `DesignSystem.Form` et `DesignSystem.FormList` le portent.

Les marges ne changent que si elles dépassent celles de la liste (20 pt), c'est-à-dire au-delà de 580 pt de large.
Le Duo plié n'est pas concerné.

**Les formulaires ont un titre en ligne**. `DesignSystem.Form` et `DesignSystem.FormList` posent
`.navigationBarTitleDisplayMode(.inline)`, et `ListFormView` le dit aussi, comme les autres formulaires le faisaient
déjà. Un grand titre n'apportait rien que le premier champ ne dise. Dans une feuille d'environ 650 pt, il restait en
plus calé sur la marge de la barre, à 40 pt à gauche des champs resserrés.

**« Tous les livres » passe sur deux colonnes au-delà de 700 pt** (`ShelvesContent.twoColumnThreshold`), donc
seulement déplié en paysage. Les livres vont par rangées de deux, lues de gauche à droite, avec un filet sous chaque
rangée. Il n'y a pas de balayage dans ce cas, à la demande du propriétaire : le menu contextuel de chaque livre suffit.
Sur iPhone et déplié en portrait, la liste reste sur une colonne, inchangée.

## Ce qui n'a pas changé

La colonne système sur le bord droit : le propriétaire l'a acceptée telle quelle.

## Tests

- `SortGridMetricsTests` couvre les largeurs du Duo. Les cartes d'un iPhone restent sur trois colonnes ; un écran
  large ajoute des colonnes sans dépasser les plafonds ; la carte qui dépasse se voit toujours ; chaque couverture,
  en pile ou sur une carte, est en 2:3 et tient dans sa zone.
- `ShelfCardMetricsTests` : un iPhone garde ses 86 %, le Duo s'arrête à 370 pt.
- `ReadableWidthTests` : aucun iPhone ni le Duo plié ne change ; déplié, la colonne fait 540 pt.

## Vu, et pas vu

Vu sur le simulateur, déplié en portrait et en paysage : « Ranger mes livres », « Chez mes amis », le carrousel
d'étagères, « Tous les livres » sur deux colonnes, la fiche livre et le formulaire de liste en feuille. Vu plié une
fois connecté : l'inventaire et « Ranger mes livres ».

Pas vu :

- l'accueil, la connexion, la création de compte et le mot de passe oublié dans leur nouvelle largeur, qui demandent
  d'être déconnecté ;
- « Create an account », qui n'avait pas réagi pendant la revue, quand les taps de l'outil arrivaient mal en paysage ;
- le scanner, faute de caméra ;
- un iPhone, en dehors de la suite de tests.

Le scénario e2e n'a pas été lancé.
