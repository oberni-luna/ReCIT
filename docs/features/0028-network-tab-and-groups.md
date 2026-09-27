# Un onglet Réseau, et les groupes d'inventaire.io

Shipped on 2026-09-27. Le PRD (`docs/prd/0016-network-tab-and-groups.md`) et les issues
0099–0101 ont été supprimés à ce commit ; ils n'avaient jamais été commités. Maquettes : section
Figma `Réseau · Onglet & Groupes` (`499:14069`), décrite en fin de
[figma-library.md](../design-system/figma-library.md).

## Ce que ça fait

**Un onglet à part.** Le réseau vivait au milieu du Profil, entre les transactions et la
déconnexion : une invitation y poussait tout vers le bas, et rien dans la barre d'onglets ne
disait qu'elle était arrivée. Il a maintenant le 4e onglet, « Réseau » (`person.2`), entre
Listes et Profil, avec un segmented control **Amis | Groupes** en tête de liste. L'onglet porte
un badge : invitations d'amis reçues, invitations de groupe, demandes à valider dans mes groupes
d'admin. Le « + » de la barre suit le segment : ajouter un ami, créer un groupe. L'app s'ouvre
désormais sur l'Inventaire.

**Amis** reprend, sans les redessiner, les deux sections que portait le Profil (feature 0018) :
les invitations reçues, puis les amis et « Ajouter des amis lecteurs ». Le Profil ne garde que le
compte, l'étiquette inventaire.io, les transactions et les deux lignes de fin.

**Groupes** liste, dans cet ordre, les invitations à rejoindre un groupe (qui a invité, Accepter
/ Refuser), mes groupes (étiquette « Admin » sur les miens), les demandes envoyées qui attendent
un admin, puis « Trouver un groupe » et « Créer un groupe ». Sans aucun groupe, un état vide dit
ce qu'est un groupe et mène aux deux.

**Trouver** cherche par nom parmi les groupes visibles, dans l'ordre du serveur. La ligne ouvre
le groupe.

**La fiche d'un groupe** relit le groupe à chaque ouverture et montre ce que ma place permet :

- *pas membre* : « Rejoindre le groupe » s'il est ouvert, « Demander à rejoindre » sinon, et la
  phrase qui dit lequel des deux va se passer ;
- *demande envoyée* : un bouton inerte et « Annuler la demande » ;
- *invité* : qui m'a invité, Accepter, Refuser ;
- *membre* : les membres (cinq, puis « Voir les N membres ») et « Inviter des amis » ; le « … »
  porte Inviter et Quitter, derrière une confirmation — refusé au dernier admin d'un groupe qui a
  encore des membres, avec la phrase qui explique ;
- *admin* : en plus, les demandes à valider en tête, et « Réglages du groupe » dans le « … ».

**Les membres** sont rangés par rôle : admins, membres, demandes à valider (admins seulement),
invitations envoyées. Un admin a un « … » sur chaque ligne de membre : Nommer admin, Retirer du
groupe, chacun confirmé. Jamais sur la ligne d'un autre admin.

**Inviter** liste mes amis avec leur place dans le groupe : Inviter, « Invitation envoyée »,
« Déjà membre », « A décliné » ; pour un ami qui avait demandé, la pilule dit Accepter.

**Créer** est une feuille : nom (1 à 80 caractères, vérifié à la frappe), description, « Visible
dans la recherche » (oui par défaut), « Ouvert à tous » (non par défaut). Le groupe créé s'ouvre.

**Les réglages** sont une feuille : les interrupteurs s'écrivent au mouvement, le nom et la
description sur « Enregistrer ». L'adresse du groupe (`slug`) est rappelée sous les champs.

## Ce que le serveur sait faire

Vérifié le 2026-09-27 contre `https://inventaire.io/public/api_specs.json` et
`codeberg.org/inventaire/inventaire` (`server/models/group.ts`,
`server/controllers/groups/lib/membership_validations.ts`, `leave_groups.ts`).

| Besoin | Endpoint |
|---|---|
| Mes groupes | `GET /api/groups` — admin, membre ou invité ; **pas** `requested` |
| Un groupe et ses gens | `GET /api/groups/by-id?id=` → `{ group, users }` |
| Chercher | `GET /api/search?types=groups&search=` → `id`, `label`, `description?`, `image?`, `_score` |
| Créer | `POST /api/groups {name, description, searchable, open}` → le document |
| Un geste | `PUT /api/groups/<action> {group, user?}` |
| Un réglage | `PUT /api/groups/update-settings {group, attribute, value}` |

## Surface technique

- `Model/Groups/` — `ReaderGroup` (valeur, les cinq listes de rôles, `role(of:)`, `canLeave`,
  `applying(_:by:on:)`), `GroupMembership`, `GroupRole`, `GroupAction`, `GroupSetting`,
  `GroupTransitionError`, `GroupSearchResult`.
- `AppModels/Group/` — `GroupModel` (`@Observable`, en mémoire), `GroupRequestLedger`
  (`UserDefaults`), les DTO et les corps de requête. `GroupDTO` remplace l'ancien, qui ne savait
  ni `invitor: null` ni trois rôles sur cinq.
- `Features/Network/` — `NetworkView`, `NetworkSegment`, `FriendsSegmentView`,
  `GroupsSegmentView`, et `Groups/` pour la fiche, les membres, l'invitation, les deux feuilles
  et les lignes.
- `NavigationDestination` : `.group(id:)`, `.findGroups`, `.groupMembers(id:)`,
  `.inviteToGroup(id:)`.
- `User.upsert(_:baseUrl:in:)` sort de `UserModel.getOrFetchUsers`, partagé avec les groupes.
- `UserGroup` (`@Model` hors schéma, jamais lu) et `CommunityView` (l'onglet caché) supprimés.
- Tests : `ReaderGroupTests` (12), `GroupModelTests` (7 + 3).

## Décisions notables

- **En mémoire, pas en SwiftData.** Un nouveau `@Model` aurait été une migration de store. Les
  groupes sont relus à chaque lancement ; leurs membres, eux, sont des `User` du store. Un état
  de chargement propre au modèle (`hasLoaded`, `syncFailed`) remplace `SyncStatusStore`, dont le
  marqueur persistant dirait « synchronisé » devant un dictionnaire vide.
- **Les transitions du serveur, rejouées.** `ReaderGroup.applying` reprend
  `groupMembershipActions`, raccourcis compris : une demande à un groupe ouvert fait entrer, une
  demande d'un invité ou d'un « a décliné » fait entrer, une invitation à qui avait demandé
  l'accepte. D'où des gestes optimistes (ADR 0001) qui montrent l'état que le serveur va écrire.
  Un geste que le serveur refuserait (inviter qui a décliné, partir en dernier admin) est signalé
  et ni montré ni envoyé.
- **Les demandes envoyées, retenues.** `GET /api/groups` ne les rend pas ; leurs ids sont gardés
  par compte et relus par `by-id` à chaque sync. Une demande faite sur le site n'est connue ici
  qu'une fois acceptée.
- **Créer n'est pas optimiste** : création limitée en débit, filtre anti-spam, slug fait par le
  serveur, et la fiche qui suit a besoin de l'id rendu.
- **Endpoints canoniques** (`/api/groups/<action>`), pas la forme `?action=` dépréciée.

## Écarts avec la maquette

| Point | Figma | Code |
|---|---|---|
| Créer (`A11`), Réglages (`A12`) | écrans poussés | feuilles, comme les formulaires d'étagère et de liste |
| Recherche (`A4`) | pilule « Rejoindre » en fin de ligne | pas de pilule : la recherche ne dit pas si le groupe est ouvert ; la fiche le sait |
| Livres du groupe (`A6`) | section et lien | **absents** |
| Photo, lieu (`A11`, `A12`) | présents | **absents** |
| « Inviter par e-mail » (`A10`) | présent | **absent** |
| « … » membre (`A7`) | Inviter, Signaler, Quitter | Réglages (admin), Inviter, Quitter — pas de signalement |
| `A12` | membres et « Quitter » dans les réglages | dans la fiche et son « … » |
| Tags de `Group Header` | sans glyphe | avec glyphe (`lock` / `door.left.hand.open`, `person.2`) : `TagLabelStyle` en porte toujours un |
| Badge d'onglet | non dessiné | présent |

## Non fait / non vérifié

- **Rien n'a été vu sur un appareil ni même lancé connecté** : construit, suite unitaire verte
  (710 / 711, un test ignoré préexistant), aucun passage à l'écran avec un vrai compte, aucun
  `scripts/e2e.sh`. Le scénario n'utilise aucun des identifiants déplacés du Profil, mais son
  `Tab.settings` cherche « Réglages » là où l'onglet dit « Profil » — c'était déjà le cas.
- Reporté : les livres d'un groupe (`items/inventory-view?group=` ramènerait les livres
  d'inconnus, qu'il faudrait garder hors du store et de la recherche d'inventaire), la photo
  (`/api/images/upload?container=groups`), le lieu, l'invitation par e-mail
  (`POST /invitations/by-emails`), le signalement d'un groupe, le partage d'étagères et de listes
  avec un groupe (visibilité `group:<id>`).
- Mode sombre non relu (tout est en tokens).
