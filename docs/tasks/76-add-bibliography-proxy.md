---
issue: 76
status: todo
wiki: [[architecture]], [[features/0013-welcome-cover-wall]], [[features/0047-new-book-work-first]], [[features/0050-every-bibliographic-datum]], [[features/0051-edition-duplicates]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #69 (skeleton). #73 and #74 read inventaire.io through its client; #77 adds the signed writes.
created: 2026-11-07
---

## Context / Decisions

> entities, data, search, covers, recent-public relayed
>
> Part of #62. Pass-through, no cache: /api/entities/* reads, /api/data/*, entity search types, /img/entities/*, /img/remote/* (author photos, found in #71's grill), /api/items/recent-public, /api/items/by-entities without a session (copy count of feature 0051, found in #73's grill), /api/tasks/by-uris (merge tasks, found in #73's grill). Every relayed request carries a header naming Ex-libris (User-Agent). Biblio writes answer an error until the signed writes task.

The apps call only the Ex-libris backend (#62). Everything bibliographic it does not own, it relays to inventaire.io unchanged, so the book screen, editions, authors, search, the scanner's lookups, the duplicate review and the welcome wall of covers work as today. One package `entities`.

1. **Relayed by prefix, reads only**, query string as sent:
   - every `GET` under `/api/entities/*`, `/api/data/*`, `/api/tasks/*`, `/img/entities/*`, `/img/remote/*`;
   - `GET /api/search` when every type asked is an entity type (`works`, `humans`, `series`, `publishers`, `collections`, `editions`…); `users` and `groups` are #71 and #72; a request mixing both answers `400` (#62);
   - `GET /api/items/by-entities` and `GET /api/items/recent-public`.
   Reads the apps do not call yet under these prefixes are relayed too.
2. **Without a session, with a header naming Ex-libris.** No reader's cookie or credential is sent to inventaire.io: `Cookie` and `Authorization` are dropped, `Accept`, `Accept-Language` and `If-None-Match` forwarded. Every request carries `User-Agent: Ex-libris/<version> (+<contact URL>)`, the contact URL chosen when coded. This header and the timeouts live in one `InventaireClient` (base URL from the environment, `https://inventaire.io` by default), which #73's snapshots and #74's type checks use too.
3. **The answer goes back as inventaire.io gave it**: status, body, `Content-Type`, and for images `Cache-Control`, `ETag`, `Last-Modified`; a `304` passes as `304`. `Set-Cookie` is dropped, so inventaire.io's anonymous session never reaches the apps. Bodies are streamed, not buffered.
4. **inventaire.io down**: a timeout (10 s on JSON, 30 s on images) or a refused connection answers `502` in #69's error shape (`{"status":502,"status_verbose":"bad gateway"}`).
5. **One IP for every reader.** A `429` from inventaire.io goes back to the app as is, and every one is counted in the backend's log with its path. Maxime is told the backend's IP and header before the production launch (#67). A cache comes only if those `429`s appear; #62's « no cache in v1 » holds.
6. **Bibliographic writes answer `501`** (`{"status":501,"status_verbose":"not implemented"}`) until #77: `POST /api/entities`, `POST /api/entities/resolve` (its dry run too: inventaire.io requires a session for it, and the apps already read a failed dry run as « nothing recognised »), `PUT /api/entities/update-claim`, `PUT /api/entities/update-label`, `PUT /api/entities/merge`, `POST /api/images/upload?container=entities`. Any other non-`GET` under the relayed prefixes answers the same.
7. **Wikimedia stays direct** (`commons.wikimedia.org`), as #62 decided; the Wikidata account link (feature 0070) is out of the sprint.

## Acceptance criteria

- `GET /api/entities/by-uris?uris=wd:Q8337&lang=fr` on the local backend answers the same JSON as inventaire.io for the same URL.
- `GET /api/search?types=works|humans&search=dune&lang=fr` answers inventaire.io's results; `types=users|works` answers `400`.
- `GET /api/data/isbn?isbn=9782070368228`, `/api/entities/author-works`, `/api/entities/reverse-claims` and `/api/tasks/by-uris?uris=…&type=merge` answer inventaire.io's JSON.
- `GET /img/entities/<hash>` answers the image bytes with inventaire.io's `Content-Type` and `Cache-Control`; the same request with its `If-None-Match` answers `304`.
- `GET /img/remote/<width>x<height>/<hash>?href=…` answers the image inventaire.io serves for it.
- `GET /api/items/by-entities?uris=…&limit=1` answers inventaire.io's anonymous `total`; `GET /api/items/recent-public?limit=…` answers its items.
- No relayed request reaching inventaire.io carries a reader's cookie; every one carries the `User-Agent` naming Ex-libris (seen in a test against a stub server).
- No response from a relayed route carries `Set-Cookie`.
- With inventaire.io unreachable (stub stopped), a relayed route answers `502` in #69's error shape within 10 s.
- A `429` from inventaire.io (stub) reaches the app as `429` and writes one log line with the path.
- `PUT /api/entities/update-claim`, `POST /api/entities`, `POST /api/entities/resolve` and `POST /api/images/upload?container=entities` answer `501`.
- The iOS app launched with `-ExLibrisBackend http://localhost:8080` opens a book screen with its cover, an author with its photo and works, the « Éditions » screen, a search for « dune » on inventaire.io, the welcome wall of covers, and scans an ISBN to a known edition.
