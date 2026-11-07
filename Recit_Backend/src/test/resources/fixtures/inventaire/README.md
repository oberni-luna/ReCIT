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
