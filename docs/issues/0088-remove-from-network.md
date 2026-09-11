Title: Retirer un lecteur de son réseau
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-reader-network.md` — frame `N10` (`411:11215`)

## What to build

Le « … » du profil d'un lecteur ne porte aujourd'hui que « Signaler ». Sur un ami, il gagne
« Retirer du réseau », en rôle destructif, avec la confirmation que l'app demande partout ailleurs
pour ce genre de geste (`confirmationDialog`, comme « Supprimer de mon inventaire »). La maquette
n'en dessine pas : `unfriend` défait une relation qu'il faudra redemander, et c'est le seul geste
du parcours qui perd quelque chose.

Une fois retiré : `relation` retombe à `.none`, l'inventaire du lecteur quitte l'écran et le
store, et le Profil ne le liste plus.

Cette issue clôt la feature : elle écrit `docs/features/0018-reader-network.md`, supprime
`docs/prd/0014-reader-network.md`, et note dans `docs/design-system/figma-library.md` ce que le
code a tranché autrement que la maquette.

## Acceptance criteria

- [ ] « Retirer du réseau » n'apparaît que sur un ami, jamais sur soi
- [ ] Une confirmation précède l'appel
- [ ] `UserModel.unfriend(_:)` poste `/api/relations/unfriend` et retombe à `.none`
- [ ] Les livres du lecteur retiré ne sont plus dans la recherche de l'inventaire
- [ ] `docs/features/0018-reader-network.md` existe, le PRD 0014 est supprimé, la note Figma est écrite
- [ ] `xcodebuild … -scheme ReCIT_iOSTests test` passe

## Blocked by

- `docs/issues/0083-relations-four-states.md`
- `docs/issues/0085-request-and-cancel.md`
