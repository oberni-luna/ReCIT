---
issue: 162
status: to-test
wiki: [[network]], [[features/0018-reader-network]], [[features/0028-network-tab-and-groups]], [[design-system/figma-library]]
note: Inviter par e-mail un·e ami·e ou dans un groupe, via POST /api/invitations/by-emails d'inventaire.io, en bas des recherches « Ajouter des ami·es lecteur·ices » et « Inviter des ami·es ». Maquette Figma : section « Réseau · Inviter par e-mail » (1118:5596), page Réseau.
created: 2026-11-18
---

## Context / Decisions

> Inviter par e-mail un·e ami·e ou dans un groupe, via POST /api/invitations/by-emails d'inventaire.io. Le serveur envoie une demande d'ami (ou groups/invite) aux comptes existants, et un mail inventaire.io aux adresses inconnues ; à l'inscription avec la même adresse, convertInvitations crée la demande d'ami / l'invitation au groupe.

### Ce que fait le serveur

Vérifié le 2026-11-18 sur la spec en ligne (v6.0.2) et sur le code Codeberg (`server/controllers/invitations/`).

- `POST /api/invitations/by-emails` avec `{ emails: [String], message?: String, group?: groupId }`. Il faut une session.
- 50 adresses au plus par appel (sinon `400`). Quota de 250 invitations par utilisateur·ice (`429`).
- Le serveur met les adresses en minuscules, retire les doublons et retire l'adresse de l'expéditeur·ice.
- Adresse d'un compte existant : demande d'ami·e (ou invitation au groupe), pas d'e-mail.
- Adresse inconnue : e-mail d'inventaire.io. Son lien mène à `inventaire.io/users/<pseudo>` ou `/groups/<slug>`, pas à `link.exlibris.lunabee.ovh`.
- À l'inscription avec cette adresse, le serveur crée la demande d'ami·e ou l'invitation au groupe.
- Réponse `{ users, emails }` : `users` = comptes existants qui ont reçu une demande, `emails` = adresses qui ont reçu un e-mail.
- Pour un groupe, il suffit d'être membre (`403` sinon), pas admin.

### Où et quand

- Maquette : section Figma `Réseau · Inviter par e-mail` (`1118:5596`), écrans I1 à I5 et la carte de spec.
- Une section « Pas encore sur inventaire.io ? » ferme la liste de deux recherches :
  - « Ajouter des ami·es lecteur·ices » (`Features/Community/ReaderSearchView.swift`) : sous les résultats, ou sous l'état vide s'il n'y a aucun résultat ;
  - « Inviter des ami·es » d'un groupe (`Features/Network/Groups/InviteToGroupView.swift`) : sous les ami·es filtré·es, ou sous l'état vide.
- La section contient la ligne « Inviter par e-mail » et une note. Elle apparaît dès le premier caractère tapé. Au repos, elle n'est pas là.
- La ligne ouvre la feuille « Inviter par e-mail ». Si la recherche contient un @, le champ « Adresses e-mail » est prérempli avec la recherche.
- La feuille a deux champs, « Adresses e-mail » et « Message (facultatif) », une note et un bouton « Envoyer l'invitation » épinglé en bas. Depuis un groupe, elle envoie aussi `group`.
- Un champ seul pour les adresses, pas de sélecteur de contacts (pas d'UIKit, rien de plus à déclarer en confidentialité).

### Validation

- Un type pur dans `Model/` lit le champ :
  - il découpe sur `,`, `;`, les espaces et les retours à la ligne ;
  - il met en minuscules, retire les doublons et retire mon adresse ;
  - il dit quelles adresses sont mal formées.
- « Envoyer l'invitation » est grisé quand la liste est vide, quand une adresse est mal formée ou au-delà de 50 adresses. L'adresse mal formée est nommée sous le champ.

### Envoi

- Server-first, pas optimiste : il n'y a rien à montrer dans le store avant la réponse. La feature doc le dira.
- Pendant l'appel, le bouton montre une progression.
- Succès : la feuille se ferme et une SnackBar (`@Environment(\.snackBar)`) dit ce qui est parti, depuis la réponse :
  - les e-mails : « Invitation envoyée à 2 adresses » ;
  - les comptes existants : « camille.b est déjà sur inventaire.io : demande envoyée », ou un nombre s'ils sont plusieurs ;
  - une seule phrase quand il y a les deux. Texte exact avec `/wa-wording`.
- Si `users` n'est pas vide, l'app resynchronise : `syncRelations` pour un·e ami·e, le groupe pour une invitation au groupe. La personne apparaît alors « Envoyée » ou « Invitée » sans relancer l'app.
- Échec : la feuille reste ouverte et garde la saisie. Un `429` donne « Trop d'invitations envoyées. Réessayez plus tard. » (un cas sur un type pur). Le reste passe par `SnackBarView.error`.

### Où vit le code

- Types purs dans `Model/` : la liste d'adresses, le résultat qui construit le texte de la SnackBar, l'échec `429`. Le nom suit le glossaire (`EmailInvitation…`).
- L'appel réseau et son DTO dans `AppModels/User/`, à côté des écritures de relation. Pas de nouveau modèle partagé.
- La feuille `EmailInvitationSheet` et la section partagée par les deux recherches dans `Features/Network/`.

### Hors scope

- Le sélecteur de contacts iOS.
- Android : tâche draft à part, bloquée par celle-ci.
- Le contenu de l'e-mail et son lien vers le site : c'est le serveur d'inventaire.io.
- Le scénario e2e : il enverrait de vrais e-mails.
- Les réponses de confidentialité de l'App Store (adresses de tiers envoyées à inventaire.io) : à vérifier avant la release, pas de code.

## Acceptance criteria

- [ ] « Ajouter des ami·es lecteur·ices » au repos : pas de section « Pas encore sur inventaire.io ? ».
- [ ] « Ajouter des ami·es lecteur·ices », « camille » tapé, avec résultats : la section ferme la liste, sous les lecteur·ices, avec la ligne « Inviter par e-mail » et sa note.
- [ ] « Ajouter des ami·es lecteur·ices », recherche sans résultat : la section suit l'état vide « Aucun·e lecteur·ice de ce nom ».
- [ ] « Inviter des ami·es » d'un groupe, avec ou sans ami·e trouvé·e : la même section ferme la liste, ou suit l'état vide.
- [ ] La ligne ouvre la feuille « Inviter par e-mail ». Recherche « marie@free.fr » : le champ « Adresses e-mail » contient « marie@free.fr ».
- [ ] Champ vide, « marie@ » ou 51 adresses : « Envoyer l'invitation » est grisé. Pour « marie@ », l'adresse est nommée sous le champ.
- [ ] « A@b.fr, a@b.fr; c@d.fr » plus mon adresse : la requête part avec `["a@b.fr", "c@d.fr"]`.
- [ ] Envoi depuis « Ajouter des ami·es » : `POST /api/invitations/by-emails` avec `emails` et `message` s'il est rempli, sans `group`. Depuis un groupe : avec `group`.
- [ ] Succès : la feuille se ferme et une SnackBar dit combien d'adresses ont reçu l'e-mail, et nomme le compte existant s'il y en a un.
- [ ] L'adresse d'un compte existant est envoyée : après le succès, la personne apparaît « Envoyée » dans « Demandes en cours » (ou « Invitée » dans le groupe), sans relancer l'app.
- [ ] Échec réseau : la feuille reste ouverte avec la saisie, une SnackBar donne l'erreur. Réponse `429` : « Trop d'invitations envoyées. Réessayez plus tard. »
- [ ] Tests unitaires, sans réseau :
  - lecture du champ (séparateurs, casse, doublons, mon adresse, adresse mal formée, limite de 50) ;
  - texte de la SnackBar depuis `{ users, emails }` ;
  - le `429` ;
  - la requête (méthode, chemin, corps) par `MockURLProtocol`.

## Implementation

Two bricks, one implementer. Build ✅ (SwiftLint clean), the four invitation suites ✅ (36 cases). App not run.

- Pure types, `Model/Invitation/`:
  - `EmailInvitationList`: parses the field, drops own address, `canSend`, `maximumCount = 50`, `initialText(fromSearch:)` for the @ pre-fill;
  - `EmailInvitationOutcome`: SnackBar sentence from `{ users, emails }`, friend and group variants, `hasExistingAccounts`;
  - `EmailInvitationFailure`: `429` → `.rateLimited` with its sentence, else `.other`.
- Network, `AppModels/User/`:
  - `EmailInvitationPayload`: request, nil and blank message left out;
  - `EmailInvitationDTO` + `EmailInvitationUserDTO`: response, missing keys read as empty;
  - `UserModel+EmailInvitation`: `sendEmailInvitations(_:message:groupId:) async throws(EmailInvitationFailure)`, `POST /api/invitations/by-emails`, server-first. `UserModel.swift` untouched (its baseline pins 416 lines).
- Views, `Features/Network/EmailInvitation/`:
  - `EmailInvitationSection`: header, tinted row, note;
  - `EmailInvitationSheet`: built like `CreateGroupView`. Success → SnackBar, dismiss, then `syncRelations` or `GroupModel.fetchGroup` when accounts existed. A failed resync is only logged. Failure → the sheet stays open;
  - `EmailInvitationAddressesFooter`: malformed addresses, then over 50, else the note.
- `ReaderSearchView`: the section while querying, after the results or the placeholder.
- `InviteToGroupView`: the section while querying. New empty state « Aucun·e ami·e de ce nom » when friends exist but none matches; `no_friends` kept for no friends at all.
- `Localizable.xcstrings`: 27 keys, fr + en, plurals through substitutions.
- Tests: `EmailInvitationListTests`, `EmailInvitationOutcomeTests`, `EmailInvitationFailureTests`, `UserModelEmailInvitationTests`. The last uses `MockAPIService`, like `UserModelAccountTests`, not `MockURLProtocol`.
- New views type their `@Environment` (`explicit_type_interface`), like recent views.

## Review

## Verification

manual validation — not run by agent

## Feedback
