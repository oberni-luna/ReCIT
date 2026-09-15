Title: L'étagère d'un ami s'ouvre, elle ne se modifie pas
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/` — les étagères partagées d'un ami.

## What to build

L'étiquette d'une carte pousse `NavigationDestination.shelf(id:)`, donc `ShelfDetailView` — le même
écran pour mon étagère et pour la sienne. Il porte deux gestes d'écriture qui n'ont aucun sens sur
l'étagère d'un autre, et que le serveur refuserait de toute façon :

- « Modifier » dans la barre de navigation, qui ouvre `ShelfFormView` — renommer, changer la
  visibilité, **supprimer** ;
- le balayage d'une ligne, qui retire le livre de l'étagère.

**La règle est dérivée, pas transmise.** `ShelfDetailView` compare `shelf.ownerId` à
`userModel.myUser?._id`. Un paramètre `isReadOnly` peut être passé à faux par un troisième appelant
qu'on ajoutera plus tard ; la propriété, elle, ne peut pas mentir. L'écran cherche déjà son étagère
par id, donc il a l'objet sous la main avant de décider.

Les deux gestes disparaissent — ils ne sont pas désactivés en gris. Un bouton éteint pose une
question (« pourquoi ? ») à laquelle l'écran n'a pas de réponse à donner : ce n'est pas mon étagère,
et l'écran le dit déjà par son titre et par le chemin qui y mène.

Ce qui reste est exactement ce qu'on vient y chercher : la liste des livres de l'étagère, chacun
ouvrant sa fiche. **L'emprunt n'est pas ajouté ici** : la fiche du livre le porte déjà, et l'ajouter
à cet écran serait une deuxième surface à tenir en phase avec les règles de transaction.

## Acceptance criteria

- [ ] Sur l'étagère d'un ami, « Modifier » est absent
- [ ] Sur l'étagère d'un ami, le balayage d'une ligne ne propose rien
- [ ] Sur mon étagère, les deux gestes sont inchangés
- [ ] La décision est dérivée de `shelf.ownerId`, sans paramètre de lecture seule
- [ ] Un livre de l'étagère d'un ami s'ouvre sur sa fiche
- [ ] `xcodebuild -scheme ReCIT_iOSTests` passe

## Blocked by

- `docs/issues/0092-a-friends-shelves-band-on-nothing.md`
