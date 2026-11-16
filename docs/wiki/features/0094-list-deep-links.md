# Links to a list, or to one of its books, on link.exlibris.lunabee.ovh

Shipped on 2026-11-16, iOS and Android (issue #141, PR #148, third task of the « Deep links » sprint, after
[0092](0092-entity-deep-links.md) and [0093](0093-network-deep-links.md)). `https://link.exlibris.lunabee.ovh/lists/<id>`
opens the list on the Listes tab, and `/lists/<id>/element/<elementId>` opens it on that book; without the app, the
server's `302` lands on the same page on inventaire.io. Tested on Olivier's iPhone; Android built and unit-tested,
never run on an emulator.

## What it does

- **Which links.** inventaire.io's own paths (its web client's `listings.ts`). Both ids are CouchDB ids, whole-matched
  on `[0-9a-f]{32}` (checked on real lists and elements) before any request.
- **Which screen.** The list pushed alone above Listes' root, through `NavigationDestination.entityList(id:focusURI:)`.
  - On an element: the arrival of « Dans les listes » ([0079](0079-the-lists-a-book-is-in.md)), springing from the first
    book to that one with the tinted halo. The element is found by its `_id` among the list's elements; one that is no
    longer there opens the list on its first book.
  - My list stays editable; anyone else's opens read-only, as a friend's.
- **A list the store does not hold** — a stranger's public list, or a friend's not yet synced — is read through
  `GET /api/lists/by-ids?ids=<id>&with-elements=true`, upserted alone with its creator, the creator fetched too. An
  answer without a `creator` is not stored: unstamped, a list passes for mine.
  - A stranger's list shows neither in « Mes listes » nor in « Dans mon réseau », and stays in the store until sign-out.
  - A stored list is not refetched: one linked on an element added since its last sync opens on its first book.
- **Unknown or forbidden list** (`404`), or no network → inventaire.io's page in the browser.

## Technical surface

- **Server** — `scripts/deeplinks/apple-app-site-association` gains `/lists/*`.
- **iOS**
  - `DeepLink.list(id:elementId:)`; `init?(url:)` split into `list(at:)` and `page(at:)`, `isCouchId`.
  - `AppModels/List/ListModel+DeepLink.swift`: `storedList(id:)`, `fetchList(id:)`; `ListsByIdDTO` (`by-ids` answers a
    dictionary keyed by id, unlike `by-creators`' array).
  - `AppModels/List/ListModel+Upsert.swift`: `upsertLists(_:deleteMissing:scope:modelContext:)`, the one upsert of
    lists, used by `syncLists` (pruning within its creators) and `fetchList` (no pruning).
  - `NavigationDestination(linkedList:elementId:)` maps the element to its uri. `EntityListView` applies
    `.opensPendingLink(on: .lists, path:)`.
- **Android** — `DeepLink.EntityList(id, elementId)` (not `List`, which would shadow `kotlin.collections.List`),
  `listDestination(list, elementId)`; `ListRepository.storedList(id)`, `fetchList(id)`; `ListsByIdDto`.
- **Tests** — `DeepLinkTests`, `LinkedListTests`; Android `DeepLinkTest`.

## Known limits

- A stranger's list loaded by a link is never pruned before sign-out; the network sync prunes friends' lists only.
