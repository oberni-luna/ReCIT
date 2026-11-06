# Glossary

> whackagent convention module. One word per thing, same word everywhere: UI strings, conversation, tasks, reports, PRs, wiki, code. Yours to edit — every skill and both agents read it. Rules below are plugin text, refreshed by `/wa-update`.

## Rules

- **One thing, one term.** Listed → use it. Never a word from `Never`.
- **Also** = words people say for it. Understand them, never write them.
- **Code** = its name in source. New type, file, variable for it → that name. Existing code named otherwise → never rename unasked.
- **Means** = one line, ≤ 12 words. Detail → `→ [[wiki page]]`.
- **Missing term** → propose the row, add on yes. Never coin a second word for a listed thing.
- Short: what users see or the team argues about. Not a dictionary.
- Review: UI string with a `Never` word → `correctness`. New type or variable off `Code`, or a `Never` word in code → `style`.

## Concepts

Product objects and notions, their states, roles, plans. Users see these: one column per UI language, source first.

| fr | en | Also | Never | Code | Means |
|---|---|---|---|---|---|
| Livre | Book | exemplaire, copie | Item | `InventoryItem` | a copy I own, on inventaire.io → [[features/0007-batch-scanner]] |
| Inventaire | Inventory | bibliothèque, collection | — | `InventoryItem` (all of mine) | every copy I own, the first tab |
| Étagère | Shelf | rayon | Shelve | `Shelf` | a named group of my books, drawn as a shelf → [[features/0001-shelf-carousel-and-creation]] |
| Liste | List | sélection | Collection | `EntityList`, `EntityListItem` | works or authors gathered, commented → [[features/0060-list-cover-flow]] |
| Œuvre | Work | titre, livre | — | `Work` | the text, whatever the edition |
| Édition | Edition | version | Livre | `Edition` | one published form of a work, often with an ISBN |
| Auteur·ice | Author | écrivain | Auteur | `Author` | person who wrote a work |
| Ami·e | Friend | contact, lecteur·ice | Follower, Ami | `UserRelation`, `User` | reader linked both ways → [[features/0018-reader-network]] |
| Groupe | Group | — | Communauté | `StoredGroup` | readers sharing their books → [[features/0028-network-tab-and-groups]] |
| Échange | Transaction | demande, prêt | Order | `UserTransaction` | give, lend or sell request on a copy → [[features/0071-a-request-names-what-it-asks-for]] |
| Données bibliographiques | Bibliographic data | métadonnées | — | `EditionBibliographicClaims` | an edition's claims on inventaire.io → [[features/0050-every-bibliographic-datum]] |
| Commentaire | Comment | — | — | `InventoryItem.details` | labelled « Ce que j'en pense », seen by whoever sees the book |
| Note privée | Private note | — | — | `InventoryItem.notes` | labelled « Ce que je garde pour moi », seen by me alone |


## Screens

One precise screen. Team names, in the discussion language. UI projects only.

| Name | Also | Code | Means |
|---|---|---|---|
| Accueil | welcome, onboarding | `WelcomeView` | pre-login screen, wall of covers → [[features/0011-ex-libris-pre-login-onboarding]] |
| Inventaire | Étagères tab | `ShelvesView` | shelf carousel + « Tous les livres » |
| Listes | — | `EntityListView` | my lists, then « Dans mon réseau » |
| Liste | list detail | `EntityListDetail` | one list as a cover flow, Livres / Présentation |
| Réseau | Community | `NetworkView` | Amis / Groupes |
| Réglages du groupe | group settings | `GroupSettingsView` | what an admin changes about a group |
| Recherche | — | `SearchTabView` | unified search: mine, friends, inventaire.io |
| Profil | Settings | `ProfileView` | sheet behind the avatar → [[features/0038-profile-behind-the-avatar]] |
| Fiche livre | book screen | `BookDetailView` | one edition: cover, work, copies, actions |
| Plein écran | full screen cover | `FullScreenCoverView` | one picture alone on black, zoomable → [[features/0029-full-screen-cover]] |
| Profil d'un ami | reader profile | `UserDetailView` | Inventaire / Listes / Présentation tabs |
| Scanner | batch scanner | `BatchScanCameraView` | camera that stays open, books pile up |
| Ranger mes livres | sort, tri | `SortFlowView` | file books into shelves, by hand → [[features/0010-grid-shelf-sorting]] |
| Modifier l'édition | edit edition | `EditEditionView` | every property of an edition → [[features/0050-every-bibliographic-datum]] |
| Échange | transaction detail | `TransactionDetailView` | one request and its messages |


## Parts

A named piece of UI, reused or talked about on its own. UI projects only.

| Name | Also | Code | On | Means |
|---|---|---|---|---|
| Ligne livre | book row | `InventoryCell` | Inventaire, Profil d'un ami, Recherche | one copy: cover, title, authors |
| Étiquette papier | paper tag | — | Inventaire, Listes | tilted label naming a shelf or a first step |
| SnackBar | toast | `SnackBarView` | everywhere | background write failed or done |
| Dans les listes | in lists | `BookListsSection` | Fiche livre | the lists, mine and friends', holding the book's work → [[features/0079-the-lists-a-book-is-in]] |


## Flows

Screens chained for one goal. Steps name **Screens**. UI projects only.

| Name | Also | Steps | Means |
|---|---|---|---|
| Connexion | login, sign-in | Accueil → connexion → Inventaire | first sign-in → [[adr/0008-session-login-signup-keychain]] |
| Ajouter des livres | scan | Scanner → bilan → Ranger mes livres | scan a pile, then file it |
| Nouveau livre | create book | Scanner ou Recherche → œuvre → édition | a book inventaire.io lacks, from a scan or a search → [[features/0047-new-book-work-first]] |
