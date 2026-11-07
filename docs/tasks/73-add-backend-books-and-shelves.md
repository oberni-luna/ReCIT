---
issue: 73
status: todo
wiki: [[architecture]], [[features/0001-shelf-carousel-and-creation]], [[features/0006-shelf-membership]], [[features/0019-a-friends-shared-shelves]], [[features/0027-first-sync-progress]], [[features/0080-a-private-note-on-my-copy]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #71 (users, relations) and #72 (groups, for the `groups` visibility). #74 and #75 build on it.
created: 2026-11-07
---

## Context / Decisions

> items, shelves, visibility, inventory views
>
> Part of #62.

The backend serves the books (inventaire.io's items) and étagères (shelves) of Ex-libris readers, with inventaire.io's API, so the iOS and Android apps sync their inventory, file books on étagères and see a friend's books and étagères unchanged. Everything in #62 holds: same paths and JSON, ids in inventaire's shape, Exposed + Flyway, one package per domain (`items`, `shelves`).

1. **Thirteen routes, the whole of inventaire.io's API for them.** These are every call the two apps make for books and étagères:
   - `POST /api/items`, `GET /api/items/by-ids`, `GET /api/items/inventory-view`, `PUT /api/items/bulk-update`, `POST /api/items/delete`;
   - `/api/shelves?action=` `by-owners`, `by-ids` (with `with-items`), `create`, `update`, `delete`, `add-items`, `remove-items`, in the `?action=` form the apps send.
   `bulk-update` accepts every attribute inventaire.io accepts, not only the `transaction`, `details` and `notes` the apps send; `delete` honours `with-items` (deleting the étagère's books with it) though the apps never send it. The accepted attributes are checked against inventaire.io's live OpenAPI spec when coded.
2. **A book's snapshot is read from inventaire.io once, stored, and refreshed.** inventaire.io items carry a `snapshot` (`entity:title`, `entity:subtitle`, `entity:lang`, `entity:authors`, `entity:image`, `entity:series`, `entity:ordinal`, `entity:worksUris`, `entity:authorsUris`) built from its entities. The backend:
   - reads the edition on inventaire.io (`/api/entities/by-uris`, with its works and their authors) when a book is created, and stores the snapshot per edition URI, shared by every book of that edition, with the works' genres (`wdt:P136`) and the time it was read;
   - reads it again when a book of that edition goes through `bulk-update`, and every night for editions read more than 7 days ago;
   - follows a redirect inventaire.io answers (an edition merged into another) by moving the books to the new URI, as inventaire.io does on a merge; an edition inventaire.io no longer knows keeps its last snapshot.
   A creation whose edition inventaire.io does not know answers `400`; one made while inventaire.io does not answer fails with an error rather than storing a book without a title (`entity:title` is required by both apps' DTOs).
3. **`inventory-view` is computed in SQL from the stored snapshots**: `worksTree.author`, `worksTree.genre` and `worksTree.owner` all filled as inventaire.io fills them (the works of an author without one under `unknown`), plus `workUriItemsMap` and `totalItems`, over the books the viewer may see. No call to inventaire.io on that path.
4. **Visibility is inventaire.io's, all five values.** A book's or étagère's `visibility` is stored as sent and enforced on every read: `[]` the owner alone; `friends` accepted friends (#71); `groups` anyone sharing a group with the owner (#72); `group:<id>` that group's members, though the apps never send it (feature 0074); `public` anyone, signed in or not. A viewer who may not see a book gets the answer inventaire.io gives (absent from lists, as on inventaire.io for `by-ids`), never a hint of it. Private attributes (`notes`, `visibility` of an étagère) are stripped for anyone but the owner, as inventaire.io strips them.
5. **The user's `snapshot` is filled here.** The `items:count` and `items:last-add` that `/api/users` answers for each visibility bucket (feature 0027's progress, and the sync's « new books since » check) are computed from the books, as inventaire.io computes them; `items:last-add` moves on creation only. #71 answered them empty until now.
6. **`busy` is always `false`** here; #75 sets it while a transaction is open on the book.
7. **`GET /api/items/by-entities` is not ours.** The apps call it only for the « 3 exemplaires » of the duplicate review (feature 0051), which is about the merge on inventaire.io: #76 relays it there **without a session**, so it counts inventaire.io's public copies. Every call the backend relays to inventaire.io carries an HTTP header naming Ex-libris (a `User-Agent` such as `Ex-libris/<version> (+https://…)`), here and in #76.
8. **Account deletion** (#71) deletes the reader's books, étagères and their snapshot references; snapshots no book uses any more are left for the nightly job to drop.
9. **Removing an étagère keeps its books** (without `with-items`), only taking them off it; deleting a book takes it off every étagère.
10. **Found here for #76**: `GET /api/tasks/by-uris?type=merge` (« Doublon signalé », feature 0051) is bibliographic and relayed by #76.

### Glossary

| Word | Means |
|---|---|
| Snapshot | the copy of an edition's title, authors, cover, works and genres the backend stores beside a Livre, read from inventaire.io |

## Acceptance criteria

- With a reader signed in on the local backend, `POST /api/items` with `{"entity":"isbn:9782070368228","transaction":"inventorying","visibility":[],"shelves":[]}` answers `{"item":{…}}` whose `snapshot.entity:title` is the edition's title on inventaire.io and whose `_id` is 32 hex characters.
- `POST /api/items` with an edition URI inventaire.io does not know answers `400`.
- `GET /api/items/inventory-view?user=<me>` after that creation answers `worksTree.author`, `worksTree.genre`, `worksTree.owner`, `workUriItemsMap` and `totalItems` with the same keys and types as the fixture captured on inventaire.io, the new book's id under its work.
- `GET /api/items/by-ids?ids=<id>` answers the book with its snapshot, `total` and `offset`.
- `PUT /api/items/bulk-update` with `{"ids":[<id>],"attribute":"notes","value":"x"}` answers `{"ok":true}`, and a following `by-ids` shows `notes: "x"` to the owner and no `notes` to a friend.
- A friend sees a book with `visibility: ["friends"]` in `by-ids` and `inventory-view`; a signed-in stranger and an anonymous session do not.
- A member of a group the owner is in sees a book with `visibility: ["groups"]`; a friend outside every shared group does not.
- `POST /api/items/delete` with `{"ids":[<id>]}` answers `{"ok":true}`; the book is gone from `by-ids` and from every étagère's `items`.
- `/api/shelves?action=create`, `update`, `by-owners`, `by-ids&with-items=true`, `add-items`, `remove-items` and `delete` answer the JSON of their inventaire.io fixtures; deleting an étagère without `with-items` leaves its books in the inventory, with `with-items: true` deletes them.
- A friend sees my `friends` étagère through `by-owners`, without its `visibility`; a stranger does not see it.
- After a book is created, `/api/users?action=by-ids` for its owner answers an `items:count` one higher and an `items:last-add` at the creation time, in the matching visibility bucket.
- The nightly refresh, run by hand on an edition whose snapshot is older than 7 days, rewrites its title from inventaire.io; on an edition inventaire.io redirects, it moves the books to the new URI.
- `DELETE /api/user` removes the reader's books and étagères.
- The iOS app launched with `-ExLibrisBackend http://localhost:8080` scans a book into the inventory, files it on a new étagère, edits its Commentaire and Note privée, removes it from the étagère and deletes it; a friend's profile shows that reader's shared books and étagères.
- Every request the backend sends to inventaire.io carries the header naming Ex-libris.
