Title: La bande des étagères d'un ami, posée sur rien
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/` — les étagères partagées d'un ami.

## What to build

Sur le profil d'un ami, entre la carte d'en-tête et « Inventaire de X », une bande d'étagères :
un en-tête « Étagères de X » puis le **même carrousel que mon inventaire** — cartes à 86 % de la
largeur, aimantées, la suivante qui dépasse.

**La carte est `ShelfRowView`, inchangée.** Elle ne porte aucune affordance d'édition : on presse
un livre, il grandit, on lève et il s'ouvre ; on presse l'étiquette et on entre dans l'étagère.
Rien à retirer pour la rendre consultable — c'est ce qui permet de la reprendre telle quelle.

**Posée sur rien.** `.listRowBackground(Color.clear)`, `.listRowSeparator(.hidden)` et
`.listRowInsets(EdgeInsets())` : pas de carte plus sombre sous les étagères comme sous l'en-tête et
sous les livres, et le carrousel va d'un bord à l'autre au lieu d'être rentré dans les marges de la
`List`.

**La largeur se mesure, elle ne se devine pas.** `ShelfRowView` prend une largeur explicite parce
qu'une carte qui se mesure elle-même dans une `List` déclenche la boucle de `UICollectionView`
d'ADR 0003. Dans une ligne de `List`, un `GeometryReader` n'a pas de hauteur intrinsèque : on
mesure donc la largeur du `ScrollView` horizontal lui-même avec `onGeometryChange`, et on ne dessine
les cartes qu'une fois cette largeur connue.

**Les absences :**

- aucune étagère partagée → la bande n'existe pas, en-tête compris ;
- pas d'action « Ajouter » dans l'en-tête — on ne crée rien sur le compte d'un autre ;
- pas de carte vide : ses deux errands (scanner, ranger) sont les miens, pas les siens ;
- la bande est soumise au même `showsInventory` que les livres — un inconnu ne montre ni ses
  livres ni ses étagères.

Sur mon propre profil, la bande montre mes étagères : la requête est filtrée par `ownerId`, donc
c'est le même code qui répond, sans cas particulier.

## Acceptance criteria

- [ ] Le profil d'un ami montre ses étagères partagées entre l'en-tête et son inventaire
- [ ] Le carrousel a le comportement du mien : aimantation, presse-pour-choisir, étiquette qui
      ouvre l'étagère
- [ ] Les étagères sont posées sur le fond de l'écran, sans carte plus sombre ni marges de `List`
- [ ] Aucune action « Ajouter » sur le profil d'un autre
- [ ] Aucun ami sans étagère partagée ne laisse d'en-tête orphelin
- [ ] Le profil d'un inconnu ne montre pas de bande
- [ ] `user.shelves.header %@` est traduit en fr et en en
- [ ] `xcodebuild -scheme ReCIT_iOS` compile
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0091-a-friends-shelves-arrive-and-leave.md`
