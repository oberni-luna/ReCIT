Title: Demander à rejoindre un réseau, et annuler sa demande
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-reader-network.md` — frames `N4` (`408:10733`), `N5a` (`409:10740`), `N6` (`410:10880`)

## What to build

`UserDetailView` devient l'écran des quatre états. Pour cette issue, les deux premiers :

- **Inconnu** — « Ajouter au réseau » en `Button / Large` primaire, une note qui dit que le réseau
  est réciproque, et l'inventaire remplacé par un état vide « Inventaire privé ». Le bouton ouvre
  une feuille de confirmation (`N5a`) : qui, ce que ça fait, « Envoyer la demande » / « Annuler ».
  **Pas de champ message** — `POST /api/relations/request` ne prend qu'un identifiant.
- **Demande envoyée** — bouton inerte « Demande envoyée », puis « Annuler la demande » en
  **destructif plein** (la maquette l'a monté du lien discret au bouton), et la même note.

Les deux écritures passent par `OptimisticMutating.optimistic` : `relation` bascule localement,
l'appel part dans une tâche du modèle, un échec revient en arrière et remonte par
`AppErrorReporter`. `UserModel` gagne donc `errorReporter` et son `start(errorReporter:)`, appelé
depuis `RootView`.

## Acceptance criteria

- [ ] `UserModel.requestRelation(with:)` poste `/api/relations/request` avec `{"user": id}`
- [ ] `UserModel.cancelRelation(with:)` poste `/api/relations/cancel`
- [ ] L'état bascule avant l'appel et revient en arrière si l'appel échoue, testé
- [ ] Un échec est remonté par `AppErrorReporter`, pas avalé
- [ ] L'inventaire d'un non-ami n'est pas listé : l'état vide le remplace
- [ ] Ni l'un ni l'autre n'apparaît sur mon propre profil
- [ ] `xcodebuild … -scheme ReCIT_iOSTests test` passe

## Blocked by

- `docs/issues/0083-relations-four-states.md`
