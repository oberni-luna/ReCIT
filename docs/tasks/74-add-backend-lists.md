---
issue: 74
status: todo
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
