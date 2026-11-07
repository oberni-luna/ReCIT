# inventaire.io fixtures

What inventaire.io answers to the calls the apps make, which the backend's answers are compared with
(`FixtureAssertions`: same keys, same JSON types, same `status` / `message` / `error_type` / `error_name` / `ok`).
`context` is debugging data the apps never read: it is kept here as captured, and not reproduced.

## Two kinds, told apart by the file name

- **Captured** (`*.json`, `*.txt`): answered by `https://inventaire.io` to an **anonymous** `curl` on 2026-11-07,
  with a User-Agent naming Ex-libris. No credential was ever sent: inventaire.io's sign-in is production and
  rate-limited.
- **Derived** (`*.derived.json`): every answer that needs a session or would create an account, written from
  inventaire.io's source on Codeberg (`server/controllers/auth/*.ts`, `server/lib/error/error_handler.ts`,
  `server/controllers/user/lib/authorized_user_data_pickers.ts`), never from a call. #71 added those of
  `server/controllers/user/{update,delete}.ts`, `server/controllers/relations/*`,
  `server/controllers/images/{upload,gravatar}.ts` and `server/models/user.ts` (a new account's `snapshot`).
- `users/`, `search/` and the anonymous `401`s of `relations/` and `images/` were captured for #71 on 2026-11-07,
  the same way: `GET /api/users/by-ids`, `GET /api/search?types=users`, `GET /img/users/<hash>`.
- #72 captured, the same way on 2026-11-07, `groups/by-id*.json` (`GET /api/groups/by-id`: a group with a picture
  and no position, one with members, a request and a position, an unknown id, an invalid one, none),
  `groups/groups.anonymous.json` (`GET /api/groups` signed out), `search/groups.json` (`types=groups&search=livres`)
  and `images/img-groups.invalid-path.json`. Its `*.derived.json` come from `server/controllers/groups/*.ts`,
  `lib/membership_validations.ts`, `lib/update_settings.ts`, `server/models/group.ts` and
  `server/models/validations/group.ts`: a group created, `GET /api/groups`, `update-settings`' answers, every refusal
  of the membership actions, and an upload into `groups`.
- #76 captured, the same way on 2026-11-07, `entities/by-uris.wd-Q8337.fr.json`
  (`GET /api/entities/by-uris?uris=wd:Q8337&lang=fr`), which the relay's stub answers to prove the body comes back
  byte for byte. The relay's other tests answer from a stub: what goes through is inventaire.io's, not the backend's.

- #73 captured, the same way on 2026-11-07, `entities/by-uris.isbn-9782070368228.relatives.json` (the « 1984 »
  edition with its works, authors and series as `relatives`, the very request the backend sends for a snapshot) and
  `entities/by-uris.not-found.json`, which the snapshot tests' stub answers; `items/by-ids.json` (a public item of a
  public reader), `items/by-ids.unknown.json`, `items/inventory-view.json` (that reader's view, its lists cut to three
  entries), `items/inventory-view.missing.json`, `shelves/by-owners.json` (two of their public shelves),
  `shelves/by-ids.with-items.json` (one, its `items` cut to three) and `shelves/by-ids.not-found.json`. Its
  `*.derived.json` come from `server/controllers/items/*.ts`, `items/lib/{items,bulk_update,snapshot/*,view/*}.ts`,
  `server/controllers/shelves/*.ts`, `shelves/lib/shelves.ts`, `server/models/{item,shelf}.ts` and their
  `attributes` and `validations`: a book created, the owner's `by-ids`, every refusal of `bulk-update`, `delete` and
  the shelf actions, a shelf created, updated, filed and deleted with and without `with-items`.

## Known departures

- `status_verbose`: the skeleton's error shape (#69), repeating `message`. inventaire.io never sends it; the apps
  match the raw body, so either key serves.
- An invalid password's `message` is `invalid password`: inventaire.io's `newInvalidError` echoes the password
  itself in it.
- A `429` says `too many requests`: inventaire.io words it per limiter (`Too little time between requests`).
- `GET /api/images/gravatar` hashes the address with SHA-256 and points at `gravatar.com` (#71 decision 6);
  inventaire.io still sends an MD5 under `www.gravatar.com`. Same keys, same type: the apps only download it.
- `_score` is `pg_trgm`'s similarity, from 0 to 1, where inventaire.io sends Elasticsearch's unbounded score: the
  apps only sort by it.
- `invalid types: …`'s list of possible values is the backend's own; inventaire.io's names `genres` twice.
- Groups: no spam check on a name or a description, no creation rate limit (inventaire.io: five, two seconds
  apart), no `groupUpdate` / `userMadeAdmin` notification; `_score` is the name's `pg_trgm` similarity, where
  inventaire.io's Elasticsearch also weighs the description. `by-slug`, `slug` and `search-by-position` are not
  served: the apps never call them.
- Relayed reads (#76) answer what inventaire.io answers, minus its headers: only `Content-Type`, and for images
  `Cache-Control`, `ETag` and `Last-Modified`, come back. A JSON answer loses its `ETag`, and none carries
  `Set-Cookie`, inventaire.io's anonymous session or the backend's. Bibliographic writes answer `501` until #77,
  `POST /api/entities/resolve`'s dry run included, and an unreachable inventaire.io answers `502`.
- Books (#73): a book's snapshot is read from inventaire.io when it is created and stored per entity, read again on
  a `bulk-update` (at most once in ten minutes) and every night once a week old; inventaire.io builds it afresh on
  every read. `POST /api/items` takes an `isbn:` URI, and an entity inventaire.io redirects, and stores the book under
  the URI inventaire.io answers (inventaire.io refuses both with `400`). A snapshot that cannot be built (no title,
  neither an edition nor a work) refuses the creation with `400` where inventaire.io stores a book with an empty
  snapshot. `busy` is always `false` until #75. `by-ids`' `with-users` (`users`), `context` and the deprecation
  `warnings` inventaire.io adds to a `?action=` or a renamed parameter are not sent. A shelf's `add-items` on an
  unknown shelf changes nothing and answers `{"shelves":{}}` (inventaire.io files the books on an id that does not
  exist). Spam checks on `details` and shelf descriptions are not reproduced.
