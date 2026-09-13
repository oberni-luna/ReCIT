# Supprimer son compte, depuis le bas du Profil

Shipped on 2026-09-12. Pas de PRD : la feature est sortie d'une session `grill-me` dont les
décisions sont reprises telles quelles ci-dessous.

## Ce que ça fait

La dernière section du Profil, sous « Se déconnecter » et dans un bloc à elle, pousse un écran
qui dit ce que la suppression coûte — « 115 livres seront retirés de votre inventaire », « 4
étagères seront supprimées », « 2 listes seront supprimées », « 1 échange en cours sera annulé » —
avant un bouton rouge qui, lui, ouvre l'alerte qui agit. Deux gestes, parce qu'un doigt qui glisse
dans une liste ne doit pas pouvoir effacer une bibliothèque.

L'écran dit aussi les deux choses qu'on ne devine pas : le compte est hébergé par inventaire.io et
le supprimer ici le supprime aussi sur le site, et le nom d'utilisateur restera réservé.

Confirmé, l'app appelle `DELETE /api/user`, puis efface tout ce qu'elle avait de ce compte et
retourne à l'écran d'accueil. Échec : rien n'est effacé, le bouton redevient actif, la raison
passe dans une SnackBar.

C'est aussi ce que la règle 5.1.1(v) de l'App Review exige : une app qui crée des comptes doit
permettre de les supprimer depuis l'app. Avant cette feature, la seule voie était un e-mail.

## Ce que fait le serveur

`DELETE /api/user`, authentifié, **sans paramètre ni corps**, réponse `{"ok": true}` — vérifié
contre la spec vivante (`https://inventaire.io/public/api_specs.json`), pas contre le miroir
GitHub archivé.

Côté inventaire
([`server/controllers/user/delete.ts`](https://codeberg.org/inventaire/inventaire/src/branch/main/server/controllers/user/delete.ts)) :

- le document utilisateur est **soft-deleted** — seuls `_id`, `_rev`, `created`, `username`,
  `stableUsername` et `anonymizableId` survivent, d'où le nom d'utilisateur qui reste pris ;
- puis, en parallèle : relations supprimées, sortie de tous les groupes, **transactions actives
  annulées**, notifications supprimées, étagères supprimées, listes et leurs éléments supprimés ;
- puis les items, après l'annulation des transactions (une transaction qui se ferme touche à
  l'état `busy` des items) ;
- puis la session est fermée côté serveur.

Pas de ré-authentification demandée, pas de délai de grâce, aucun retour arrière. C'est pour ça
que l'écran compte avant, et que la confirmation est une alerte séparée.

## Surface technique

**Écran** — `Features/Profile/DeleteAccountView.swift`, poussé par le nouveau
`NavigationDestination.deleteAccount` (id stable `"deleteAccount"`), plus une ligne dans la
dernière `Section` de `ProfileView` (`e2e.profile.deleteAccount`).

**Type pur** — `Model/UserData/AccountDeletionSummary.swift` : les quatre nombres, l'ordre de
lecture, la règle « pas de ligne pour ce qu'on n'a pas », et le drapeau qui décide de la phrase
sur les personnes concernées. Testé sans écran (`Tests/AccountDeletionSummaryTests.swift`).

**Appel + purge** — `UserModel.deleteAccount(modelContext:)`. Serveur d'abord, toujours : la
purge locale ne tourne qu'après un `ok`. Puis `wipeLocalStore` vide **tous** les `@Model` du
schéma, pas seulement les lignes de cet utilisateur — le cache entier avait été peuplé sous un
compte qui n'existe plus, et ce qu'on y laisserait ressortirait sous le compte suivant ouvert sur
ce téléphone. La liste des types y est explicite, pour qu'un `@Model` ajouté au conteneur et
oublié ici se voie.

**Le piège de la purge** — `wipeLocalStore` fetche et supprime **objet par objet**, pas avec
`modelContext.delete(model:)`. La forme batch court-circuite le graphe d'objets, et
`InventoryItem.edition` est une to-one obligatoire : SwiftData répond
`Constraint trigger violation: Batch delete failed due to mandatory OTO nullify inverse on
InventoryItem/edition` et **rien n'est supprimé du tout**. Écrit en batch d'abord, attrapé par
`successWipesTheStore` avant d'atteindre un téléphone — où ça aurait donné un compte supprimé côté
serveur et un inventaire fantôme affiché en local.

**Session** — `AuthService.forgetSession()` (nouveau) purge le jar et le Keychain **sans appel
réseau**, et `AuthModel.forgetSession()` bascule `isAuthenticated`. ADR 0008 tenu : rien hors
`AuthService` ne touche aux cookies ni au Keychain. Pourquoi pas `logout()` : le serveur a déjà
fermé la session en supprimant le compte, donc le `POST /auth/logout` arriverait sur une session
morte — un `401` qu'il faudrait commenter plutôt qu'éviter.

**Stores par compte** — `RecentSearchStore.clear(userId:)`, `OnboardingStore.resetWelcome(userId:)`
et `TipsStore.resetTips(userId:)` sont appelés avec l'id **lu avant** l'appel, puisque le modèle
lâche `myUser` en cas de succès. `forgetSession()` vient en dernier : il fait basculer `RootView`,
et tout ce qui suivrait tournerait sur un écran déjà remplacé.

**Réseau** — `APIServicing` gagne une surcharge `send<U>(toEndpoint:method:debug:)` sans payload.
Séparée plutôt qu'un payload optionnel : les endpoints qui ne prennent rien ne prennent rien, et
un `{}` envoyé à l'un d'eux est un corps que le serveur n'a pas demandé. Rien n'est écrit dans
`httpBody`, pas même un `Content-Type`.

## Tests

`Tests/UserModelDeleteAccountTests.swift` (MockAPIService) :

- un `ok` laisse le store vide, `myUser` à `nil` ;
- l'appel est bien un `DELETE` sur `/api/user` ;
- une erreur réseau laisse **tout** en place — l'utilisateur ne doit jamais croire supprimé un
  compte encore vivant ;
- un `{"ok": false}` est traité comme un échec, pas comme une suppression.

`Tests/AccountDeletionSummaryTests.swift` : ordre de lecture, zéros non affichés, compte vide,
drapeau des transactions, identité de ligne stable entre deux rendus.

**Rien dans le scénario E2E**, volontairement : il joue sur un vrai compte inventaire.io
(`OlivierB_test2`) et le supprimerait pour de bon. Si on veut un jour couvrir la navigation, la
seule forme acceptable est d'ouvrir l'écran et d'annuler.

## Décisions écartées

- **Un lien vers inventaire.io** plutôt que l'appel : rejeté par l'App Review quand la création de
  compte, elle, est native (feature 0011).
- **Une demande par e-mail** : ce n'est pas une suppression, c'est une promesse.
- **Redemander le mot de passe** : le serveur ne l'exige pas, et ça casserait sur un compte
  Wikidata-OAuth.
- **Bloquer tant qu'une transaction est en cours** : met l'utilisateur à la merci d'un tiers, et
  la règle Apple interdit de conditionner la suppression.
- **Réessayer en tâche de fond** à la manière d'ADR 0001 : l'optimisme y est réservé aux écritures
  réversibles. Celle-ci ne l'est pas.
- **Un message de confirmation après coup** : le SnackBar est observé dans `MainTabView`, qui
  vient précisément de disparaître. L'écran d'accueil est la preuve.

## Reste à faire

- Les politiques de confidentialité (Notion, FR et EN) disent encore « écrivez-nous pour supprimer
  votre compte ». À reprendre : suppression depuis l'app, et la phrase sur ce que le soft delete
  conserve.
