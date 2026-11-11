# Architecture

Ex-libris is a SwiftUI + SwiftData client of [inventaire.io](https://inventaire.io), an open-data book inventory backed by CouchDB. The server owns identity (`_id`, `_rev`); the app's store is a cache of it. Android (`Recit_Android/`) is a port with Room + Compose. The rules an agent must follow are in [conventions/architecture-recit.md](../conventions/architecture-recit.md); this page says why the shape is what it is.

## Three layers

| Layer | Folder | Holds |
|---|---|---|
| Screens | `Features/<Feature>/` | SwiftUI views, rendering from `@Query` or a passed `@Model` |
| Service models | `AppModels/<Domain>/` | `@Observable @MainActor *Model` classes: `APIService` + `ModelContext`, injected through the environment from `RootView` |
| Data | `Model/<Domain>/` | SwiftData `@Model` types, DTOs, pure value types |

`AppModels/` vs `Model/` looks redundant and is not: the first is reference-type behaviour, the second is data.

## Data flow

Decided in [ADR 0001](adr/0001-swiftdata-reactive-optimistic.md):

- **UI bound to SwiftData.** A view never displays what a method returned.
- **Server → app: upsert in place.** Object identity survives a sync, so open screens stay live. Feature [0030](features/0030-entities-upserted-in-place.md) extended it to works, authors and editions.
- **App → server: optimistic.** Local write first, request in the background, reconcile or revert; failures reach a SnackBar through `AppErrorReporter`.
- **Measured.** Each phase of the launch sync and each inventory sync is a signpost interval under `asso.recits`; the cost of the first sync is in [performance](performance.md).

## Sessions

[ADR 0008](adr/0008-session-login-signup-keychain.md): cookie sessions captured by `AuthService`, kept in the cookie jar and the keychain, public traffic through a cookieless session. Two releases broke by changing one piece without the others — read the ADR first.

A failed sign-in reaches the screen as one of a few sentences owned by `AuthFailure`, never as the server's prose: wrong credentials, no network, too many attempts (a `429`, since [0083](features/0083-rate-limited-sign-in-message.md)), and one generic sentence for the rest.

## The book screen

[ADR 0002](adr/0002-unified-book-detail.md): one screen over Work / Edition / InventoryItem. A search result is a work; tapping it resolves the best edition (`EditionRelevance`, `WorkEditionResolver`) and remembers it (`Work.preferredEditionUri`).

## Shelves and sorting

[ADR 0003](adr/0003-bookshelf-inventory.md) (the étagère screen), [0004](adr/0004-shelf-creation-write.md) (creating one), [0005](adr/0005-shelf-tap-selection.md) and [0006](adr/0006-shelf-press-selection-scrim.md) (selecting a book), [0007](adr/0007-modal-sorting-flow.md) (sorting as one modal).

## Navigation

Each tab root and modal flow owns its `NavigationStack`; `NavigationDestination` is the single enum of detail screens. Cross-tab requests go through `TabRouter` (features [0037](features/0037-search-tab.md), [0038](features/0038-profile-behind-the-avatar.md)).

## Subsystems

- [Inventaire et étagères](shelves.md)
- [Scanner et « Ranger mes livres »](scanning-and-sorting.md)
- [Fiche livre, œuvres et éditions](book-and-editions.md)
- [Recherche](search.md)
- [Listes](lists.md)
- [Réseau, amis, groupes, échanges](network.md)
- [Compte, accueil et Profil](account-and-profile.md)
- [Plateformes et design system](platform-and-design.md)
- [Android](android.md)
- [Tests et scénario end-to-end](testing.md)
- [Performance iOS](performance.md) — sync and screen signposts, how a trace is recorded, the baseline
