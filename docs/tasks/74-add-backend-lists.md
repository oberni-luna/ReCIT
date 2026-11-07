---
issue: 74
status: to-test
wiki: [[architecture]], [[features/0060-list-cover-flow]], [[features/0061-move-to-another-list]], [[features/0068-lists-in-my-network]], [[features/0073-a-lists-presentation-tab]], [[features/0074-a-lists-visibility-in-its-form]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #73 (visibility rules, nightly job). Group lists (#63) and list element discussions (#66) build on it later.
created: 2026-11-07
---

## Context / Decisions

> lists and elements, same API
>
> Part of #62. /api/lists/*, elements.

The backend serves the lists of Ex-libris readers and their elements with inventaire.io's API, so the Listes tab, a list's cover flow, « Déplacer dans une autre liste » and « Dans mon réseau » work unchanged on iOS and Android. Everything in #62 holds: same paths and JSON, ids in inventaire's shape, Exposed + Flyway, one package `lists`.

1. **Seven routes, the whole of inventaire.io's API for them.** These are every call the two apps make for lists:
   - `GET /api/lists/by-creators` (with `with-elements`, `users` up to fifty per call as feature 0068 sends);
   - `POST /api/lists` (create), `PUT /api/lists` (update), `POST /api/lists/delete`;
   - `PUT /api/lists/add-elements`, `PUT /api/lists/remove-elements` (by URI), `PUT /api/lists/update-element` (comment).
   Each accepts every parameter inventaire.io accepts for it, checked against its live OpenAPI spec when coded. Routes the apps do not call (`by-ids`, `reorder`, …) are not served; deep links (#65) add what they need.
2. **A list's type and visibility are inventaire.io's.** `type` is one of the values inventaire.io accepts (works, authors, publishers); `visibility` takes the five values of #73 (`[]`, `friends`, `groups`, `group:<id>`, `public`), stored as sent and enforced on every read with the same rules as books and étagères. The list's own `visibility` is stripped for anyone but its creator, as inventaire.io strips it.
3. **`add-elements` checks each URI on inventaire.io**, as inventaire.io does:
   - reads its type through `/api/entities/by-uris`, without a session and with the header naming Ex-libris (#73);
   - answers inventaire.io's error when the entity is not of the list's type, or unknown;
   - stores the target of a redirect rather than the URI sent;
   - creates nothing for a URI the list already holds and answers it as inventaire.io does (`alreadyInList`), which feature 0061's move relies on;
   - gives new elements the next `ordinal`, as inventaire.io does.
   An addition made while inventaire.io does not answer fails with an error. Elements store only the URI, the comment and the ordinal: no snapshot, the apps read covers through the proxy (#76).
4. **The nightly job of #73 also checks element URIs.** A URI inventaire.io now redirects is replaced by its target. When the list already holds the target, the redirected element is deleted; its comment is kept on the target when the target has none.
5. **Only the creator writes** a list and its elements in this task, as on inventaire.io. Group lists (#63) widen it later.
6. **Account deletion** (#71) deletes the reader's lists and their elements.

## Acceptance criteria

- With a reader signed in on the local backend, `POST /api/lists` with `{"name":"Polars","description":"","visibility":[],"type":"work"}` answers `{"list":{…}}` with a 32-hex `_id`, and `by-creators?users=<me>&with-elements=true` returns it with `elements: []`.
- `PUT /api/lists/add-elements` with a work URI answers `{"ok":true,"createdElements":[…]}`, the element carrying `uri`, `ordinal`, `list` and a 32-hex `_id`.
- Adding an author URI to a list of works answers inventaire.io's type error and creates nothing.
- Adding the same work twice creates nothing the second time and answers it as inventaire.io answers `alreadyInList`.
- Adding a URI inventaire.io redirects stores the redirect's target.
- `PUT /api/lists/update-element` with `{"id":<element>,"comment":"x"}` answers the element with `comment: "x"`.
- `PUT /api/lists/remove-elements` with `{"id":<list>,"uris":[<uri>]}` removes the element; `by-creators` no longer returns it.
- `PUT /api/lists` changes name, description and visibility; `POST /api/lists/delete` answers `{"ok":true,"lists":[…]}` and the list is gone with its elements.
- A friend sees my `friends` list in `by-creators`, without its `visibility`; a signed-in stranger and an anonymous session do not; a friend's write on it is refused.
- `by-creators` with fifty users answers the lists each viewer may see, in inventaire.io's order.
- Every route answers the JSON of its fixture captured on inventaire.io (keys, types, error codes).
- The nightly job, run by hand on an element whose URI inventaire.io redirects, replaces it by the target; on a list that already holds the target, only one element remains, carrying the comment.
- `DELETE /api/user` removes the reader's lists and their elements.
- The iOS app launched with `-ExLibrisBackend http://localhost:8080` creates a list, adds a book to it by search, comments it, moves it to another list, removes it and deletes the list; « Dans mon réseau » shows a friend's shared list.

## Implementation

stacked on: wa/73-add-backend-books-and-shelves @ b47993b

- **Migration `V6__lists.sql`:** `lists` (cascade on `users`), `list_elements` (cascade on `lists`, `UNIQUE(list_id, uri)`, `previous_uris`, `uri_checked`).
- **Package `lists`:** `ListsRoutes`, `ListsService`, `ListElementsService`, `ElementUrisService` (nightly fix-up of redirected element URIs, comment kept, merged when the target is already in the list), repositories, `ListEntitiesChecker` (type and redirect checks on inventaire.io), `ListImagesSampler` (`attributes=images`), `LexicographicOrdinals`, `ListRules`, documents.
- **`items/InventaireEntitiesReader`:** the one way to `/api/entities/by-uris`; `SnapshotsService` moved onto it. `SnapshotRefreshJob` also runs the element-URI round, each half catching its own failure.
- All 7 routes in path and `?action=` forms, legacy POSTs included. Apps unchanged.
- **Decision 2 not applied, on purpose:** the spec says a friend sees my `friends` list « without its `visibility`, as inventaire.io strips it ». inventaire.io does not strip it (anonymous capture of `by-creators` shows `"visibility":["public"]`; Codeberg's `by_creators.ts` / `filterVisibleDocs` keep it), and stripping it would break iOS, whose `ListDTO.visibility` is a non-optional `[String]` — « Dans mon réseau » would decode nothing. Parity kept; the choice is one line in `ListRecord.document()`.
- **Other differences from inventaire.io:** the redirect target is stored (inventaire.io stores the URI sent), and a URI whose target is already in the list comes back in `alreadyInList`; `update-element` takes `id`, `comment`, `list` as the live API 5.1.1 (Codeberg main's `ordinal-after/before` not served); `by-creators` accepts `limit` (default 100), `offset`, `context`, `with-elements`, `attributes=total|images`; covers sampled in the `Accept-Language` language; first ordinal `11`; inventaire.io down → 502, nothing written; no spam checks, no `warnings`.
- **For #75:** `InventaireEntitiesReader.read(uris, parameters)`; `ListsService.wrongUser()` pattern; `VisibilityValidator.isKey`; the two-halves pattern of `SnapshotRefreshJob.attempt`; FK cascades; `ListsTestKit.entitiesAnswer`; `seedCreator` (seed many readers by SQL past the sign-up limit). Next migration V7.

## Verification

- `./gradlew build`: 205 tests green, ktlint and detekt clean. iOS `ReCIT_iOSTests` (1327) green; Android build + 607 unit tests green.
- Every backend criterion replayed by curl against real inventaire.io type checks (create, add, wrong type 403, same work twice → `alreadyInList` without calling inventaire.io, real Wikidata redirect stored as its target, comment, remove, update, delete, friends / stranger / anonymous visibility and the friend's writes refused, fifty-creator query, the nightly round run by hand, account deletion). ~21 anonymous GETs, no 429.
- **iOS, iPhone 17, local backend, as `exlibris_ios_70`:** Listes shows « À relire » and « Polars nordiques », then « Dans mon réseau » with `exlibris_friend_71`'s « Entre ami·es » and « Lectures d'automne », not the stranger's private list; + › « Liste test 74 » (`POST /api/lists 201`); Rechercher « dune » › + on Dune (`add-elements`); Mon commentaire « Le premier du cycle » (`update-element`); Déplacer dans une autre liste › « À relire » (`add-elements`, `update-element`, `remove-elements`; « À relire » now shows Dune); crayon › Supprimer la liste (`POST /api/lists/delete`).
- Android not run on screen (the Mac's load froze the emulator during #73); the Android app is unchanged.
