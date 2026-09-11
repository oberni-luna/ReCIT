Title: Chercher un lecteur par son nom, depuis le Profil
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-reader-network.md` — frames `N2` (`407:10451`) et `N3` (`408:10585`)

## What to build

La porte d'entrée : « Ajouter des amis lecteurs », en pied de la section « Réseau » du Profil,
pousse un écran de recherche.

- `NavigationDestination.addFriends`, poussée depuis un `Row / Link` teinté sous la liste des amis.
- `ReaderSearchView` : un `.searchable`, l'état de repos qui dit ce que la recherche cherche
  (`N2`), les résultats en dessous (`N3`).
- `SearchModel.searchUsers(query:limit:)` appelle `GET /api/search?types=users&search=…`. La
  réponse des utilisateurs **n'a pas d'`uri`**, là où `SearchResultDTO.uri` est non-optionnel :
  elle a donc son propre DTO (`UserSearchResultsDTO`), plutôt qu'un champ rendu optionnel pour
  tout le monde.
- Chaque résultat porte l'état de relation connu du store (`relation`), et le geste qui va avec :
  « Ajouter » pour un inconnu, « Envoyée » (inerte) pour une demande en cours, rien pour un ami.
  Toucher la rangée pousse le profil du lecteur.
- Un résultat inconnu du store est inséré à la volée pour pouvoir être poussé et porter son état.

Le geste d'ajout lui-même vient de l'issue 0085, faite avant celle-ci : la pilule « Ajouter » de
la rangée appelle `requestRelation`, elle ne navigue pas. Une rangée est donc deux cibles — le nom
ouvre le profil, la pilule agit.

## Acceptance criteria

- [ ] Le Profil porte « Ajouter des amis lecteurs » et pousse l'écran de recherche
- [ ] Une recherche vide ne part pas ; une recherche pleine appelle `types=users`
- [ ] Le DTO décode une réponse réelle d'`/api/search?types=users` (sans `uri`), testé
- [ ] Les trois états de rangée sont ceux du store, pas d'un état local à l'écran
- [ ] Toucher un résultat pousse `UserDetailView`
- [ ] `xcodebuild … -scheme ReCIT_iOSTests test` passe

## Blocked by

- `docs/issues/0083-relations-four-states.md`
- `docs/issues/0085-request-and-cancel.md` — la rangée porte le geste, donc il existe avant elle
