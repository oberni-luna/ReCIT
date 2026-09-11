Title: Lire les quatre états de relation, et ne plus appeler « réseau » tout le store
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-reader-network.md`

## What to build

Le socle. `GET /api/relations` renvoie déjà `friends`, `userRequested`, `otherRequested` et
`network` ; `UserModel.syncUserNetwork` ne garde que `network` et jette le reste. Tout le parcours
d'ajout se lit dans les trois listes jetées.

- `User` gagne `relation: UserRelation` (`none` · `friend` · `requestSent` · `requestReceived`),
  valeur par défaut `.none`. C'est l'état côté serveur, recopié à chaque sync, pas une vérité
  locale : un sync le réécrit toujours en entier.
- `UserModel.syncRelations(modelContext:)` remplace `syncUserNetwork` : un appel, les quatre
  listes, les utilisateurs manquants récupérés par `/api/users/by-ids`, et `relation` posée sur
  chacun. Un utilisateur du store absent des quatre listes retombe à `.none` — c'est ce qui fait
  disparaître un ami retiré ailleurs.
- `ProfileView` n'affiche plus `allUsers` moins moi, mais les seuls `relation == .friend`. La
  section « Réseau » listait jusqu'ici tout utilisateur tombé dans le store — un propriétaire vu
  dans une transaction y passait pour un ami.
- `RootView.refreshUserData` ne synchronise plus l'inventaire que des amis.

`network` reste ce qu'il est côté serveur (amis + membres des groupes) : il sert à peupler le
store, pas à décider qui est ami.

## Acceptance criteria

- [ ] `UserRelation` est un type pur, testé, et `User.relation` le persiste
- [ ] `syncRelations` pose les quatre états depuis une réponse stubée, en un seul `GET /api/relations`
- [ ] Un utilisateur absent des quatre listes repasse à `.none` au sync suivant
- [ ] La section « Réseau » du Profil ne montre que les amis
- [ ] Les inventaires synchronisés au démarrage sont ceux des amis, pas de tout le store
- [ ] `xcodebuild … -scheme ReCIT_iOSTests test` passe

## Blocked by

—
