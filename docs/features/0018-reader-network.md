# Se faire un réseau de lecteurs

Shipped on 2026-09-12. Le PRD (`docs/prd/0014-reader-network.md`) et les six issues 0083–0088 ont
été supprimés à ce commit ; git les garde.

## Ce que ça fait

Le Profil listait un réseau qu'aucun geste de l'app ne pouvait rejoindre : ni ajouter un lecteur,
ni voir qu'une invitation était arrivée. Le réseau se constituait sur le site web, l'app n'en
était que le spectateur. Elle fait maintenant les deux sens.

**Demander.** Sous la section « Réseau » — y compris quand elle est vide, qui est précisément le
moment où on en a besoin — « Ajouter des amis lecteurs » pousse une recherche par nom
d'utilisateur. Chaque résultat porte l'état de la relation en fin de ligne : une pilule
« Ajouter » pour un inconnu, une étiquette « Demande envoyée » pour ce qui est déjà parti,
« Invitation reçue » pour qui nous a devancés, rien du tout pour un ami. Le nom ouvre le profil,
la pilule agit : deux cibles, parce qu'un bouton « Ajouter » qui navigue ment sur ce qu'il fait.

Sur le profil d'un lecteur, « Ajouter au réseau » ouvre une feuille qui confirme — qui, ce que ça
fait, et que rien ne sera visible tant que ce n'est pas accepté. Une fois envoyée, le bouton
devient inerte et un bouton destructif en dessous la reprend.

**Répondre.** Une invitation reçue remonte dans le Profil, sous l'en-tête et avant les
transactions : « Accepter » et « Refuser » sous le nom du demandeur. « Toutes les invitations »
mène à l'écran qui porte aussi les demandes envoyées. Accepter fait entrer le lecteur dans le
réseau et va chercher ses livres dans la foulée.

**Retirer.** Le « … » du profil d'un ami porte « Retirer du réseau », derrière une confirmation.

## Ce que le serveur sait faire

Vérifié le 2026-09-12 contre la spec vivante (`https://inventaire.io/public/api_specs.json`).

| Besoin | Endpoint | Paramètres |
|---|---|---|
| Les quatre états, en un appel | `GET /api/relations` | — ; `friends`, `userRequested`, `otherRequested`, `network` |
| Demander · Annuler | `POST /api/relations/request` · `/cancel` | `user` |
| Accepter · Refuser | `POST /api/relations/accept` · `/discard` | `user` |
| Retirer | `POST /api/relations/unfriend` | `user` |
| Chercher un lecteur | `GET /api/search?types=users&search=…&limit=…` | public ; `id`, `label`, `image`, `_score`, **pas d'`uri`** |

Trois conséquences qui se voient dans les écrans :

- **Une demande ne porte pas de message.** `request` ne prend qu'un identifiant. La frame `N5b`
  de la maquette dessinait un champ de texte : elle a été écartée plutôt qu'implémentée avec un
  message qui n'irait nulle part.
- **Le serveur ne prévient personne.** Pas de notification : une invitation ne se découvre qu'en
  ouvrant l'app. C'est ce qui la fait remonter dans le Profil, et pas seulement dans un écran
  qu'il faudrait penser à ouvrir.
- **`network` n'est pas l'amitié.** Il contient aussi les membres de mes groupes. Il dit quels
  utilisateurs aller chercher, pas qui est proche de moi.

## Surface technique

**État** — `Model/UserData/UserRelation.swift` : `none` · `friend` · `requestSent` ·
`requestReceived`, plus la fonction pure qui range les quatre listes du serveur par identifiant.
La seule règle qui vaut un test est la précédence : `friends` gagne sur les deux attentes, parce
que le serveur peut porter une demande périmée à côté d'une relation acceptée, et qu'un ami avec
un bouton « Accepter » est le pire des deux mensonges. `User.relation` la persiste, et
`update(with:)` n'y touche **jamais** : `/api/users/by-ids` ignore tout des relations, et une
réponse creuse ne doit pas rétrograder un ami.

**Lecture** — `UserModel.syncRelations(modelContext:)` remplace `syncUserNetwork`. L'écriture est
exhaustive : tout utilisateur du store que la réponse ne nomme pas retombe à `.none`. C'est ce qui
fait disparaître une relation défaite ailleurs, au lieu de la laisser survivre en ami que personne
ne voit plus.

**Écritures** — cinq, toutes par `OptimisticMutating.optimistic` (ADR 0001) : l'état bascule,
l'appel part dans une tâche du modèle, un refus revient en arrière et parle par
`AppErrorReporter`. Deux d'entre elles font quelque chose de plus au `reconcile`, c'est-à-dire
**après** l'accord du serveur :

- `acceptRelation` synchronise l'inventaire du nouvel ami — sinon son profil, ouvert dans la
  foulée, dit « Oh, c'est vide ici » jusqu'au prochain lancement ;
- `unfriend` supprime ses exemplaires du store et remet `lastInventorySync` à `nil`. Après, jamais
  avant : un inventaire supprimé ne se rattrape pas par un revert, là où une relation, si.

**Recherche** — `UserModel.searchReaders(query:modelContext:)`, deux appels. `/api/search` classe
des identifiants, `/api/users/by-ids` en fait des `User` du store avec leur nombre de livres — et
c'est le fait d'être dans le store qui permet d'être poussé comme destination et de porter une
relation. Des inconnus s'y accumulent donc, volontairement : depuis cette feature, plus rien ne
confond le store avec le réseau (le Profil filtre sur `relation == .friend`, et seuls les amis
voient leur inventaire synchronisé au démarrage).

`UserSearchResultsDTO` est un type à part parce qu'un résultat utilisateur n'a **pas d'`uri`**, là
où `SearchResultDTO.uri` est non-optionnel. Rendre ce champ optionnel pour tout le monde aurait
plié la recherche d'entités autour d'un payload qui est simplement d'une autre forme.

**Écrans** — `Features/Community/` : `ReaderSearchView` (recherche), `ReaderRowView` (la rangée à
état), `InvitationRowView` (la rangée à deux réponses), `InvitationsView` (les deux sens),
`RelationActionsView` et `RelationRequestSheet` (le profil d'un lecteur). Deux destinations
nouvelles, `addFriends` et `invitations`. `InvitationsView` ne fait **aucun appel** : ses deux
listes sont des `@Query`, donc répondre depuis le Profil redessine l'écran derrière, et
inversement.

**Design system** — `PillButtonStyle` (`DesignSystem/ButtonStyles/`), qui est `Action / Pill` de
la passe Figma : les mêmes couples de tokens que `LargeButtonStyle`, à la taille qu'un contrôle de
fin de rangée peut tenir (55 pt de haut n'entrent pas dans une rangée de 69).

## Ce que le code a tranché autrement que la maquette

| Point | Figma | Code |
|---|---|---|
| Confirmation du retrait | aucune | `confirmationDialog`, comme « Supprimer de mon inventaire » et la suppression d'une étagère : c'est le seul geste du parcours qui perd quelque chose |
| Feuille de demande avec message (`N5b`) | dessinée | non implémentée — le serveur n'a pas de champ pour la porter |
| Dates (« Envoyée le 11 septembre ») | dessinées | absentes : `/api/relations` ne renvoie que des identifiants, aucune date |
| Rangée d'une demande envoyée | pilule « Envoyée » | étiquette `Tag` secondaire — c'est un état, pas un geste ; l'annulation est sur le profil |
| Glyphes | `plus`, `clock`, `person` empruntés | SF Symbols réels (`plus`, `clock`, `envelope`, `person.badge.minus`) : la contrainte était Figma, pas iOS |

## Ce qui n'est pas fait

- **Aucun badge nulle part.** Sans notification serveur, un compteur sur l'onglet « Réglages »
  serait le minimum ; il touche à la barre d'onglets de toute l'app et n'est pas maquetté.
- **Les lecteurs à proximité** (`/api/users/nearby`) : demande une position, donc une permission
  et un écran de plus.
- **Une passe sur appareil.** Les écrans n'ont été vus ni en sombre, ni en VoiceOver, ni au plus
  grand corps de texte, ni dans les deux langues — et le scénario end-to-end ne joue pas encore ce
  parcours.
