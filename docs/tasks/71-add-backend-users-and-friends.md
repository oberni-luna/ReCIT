---
issue: 71
status: todo
wiki: [[network]], [[account-and-profile]], [[features/0018-reader-network]], [[features/0055-profile-editing]], [[features/0017-deleting-your-account]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #70 (sign-in, users table). #72 and #73 build on it.
created: 2026-11-06
---

## Context / Decisions

> users, relations, reader search, avatars
>
> Part of #62. /api/user, /api/users/*, /api/relations, search types=users (pg_trgm), /img/users/*.

The account, the profile and the friendships, served as inventaire.io serves them, so Profil, Modifier le profil, Compte et connexion, Réseau › Amis and Profil d'un ami work against the backend unchanged.

### Routes the apps call (read from the iOS and Android sources)

- `GET /api/user`, `PUT /api/user` (`{attribute, value}`, one per call), `DELETE /api/user`
- `GET /api/users/by-ids?ids=…`
- `GET /api/search?types=users&search=…`
- `GET /api/relations`, `POST /api/relations/request|cancel|accept|discard|unfriend` (`{user}`)
- `POST /api/images/upload?container=users`, `GET /api/images/gravatar`
- `GET /img/users/<hash>`

### Decisions

1. **Same payloads as inventaire.io**, proven by fixtures captured there: `/api/user` returns the full account of the signed-in reader, `by-ids` the public fields of others, `/api/relations` the four lists (`friends`, `userRequested`, `otherRequested`, `network`).
2. **`PUT /api/user` accepts and stores every attribute the apps send; some take effect**:
   - `username`: rename, same rules as signup (#70);
   - `email`: the address goes back to unconfirmed and a confirmation e-mail leaves (#70's flow);
   - `language`, `bio` (0–1000 characters), `position` (rounded to the kilometre, as feature 0055 sends it), `picture`;
   - stored with no effect: the e-mail notification settings (#62), `fediversable` (no ActivityPub here), the contributions anonymity setting (used by #77).
3. **Relations follow inventaire.io's states**: one row per pair of readers, ids sorted, status `friends`, `a-requested`, `b-requested` or `none`. A request to someone who already asked me makes us friends, as on inventaire.io.
4. **Reader search**: `pg_trgm` similarity on the username, `types=users` only (#62 decision 10); a request mixing users with entity types answers `400`.
5. **Avatars**: `POST /api/images/upload?container=users` stores the file through `ImageStore` (#62 decision 15) under its hash and answers `/img/users/<hash>`; `GET /img/users/<hash>` serves it; a `/img/users/<w>x<h>/<hash>` path serves the original too (no resizing in v1).
6. **Gravatar**: `GET /api/images/gravatar` answers `{"url":"https://gravatar.com/avatar/<sha256 of the address>?d=404&s=…"}` as inventaire.io does; the app downloads it from gravatar.com itself.
7. **Account deletion** (`DELETE /api/user`, feature 0017) deletes the reader, their relations, their avatar file and their sessions, and answers `{"ok":true}`. Groups (#72), books and étagères (#73), lists (#74) and transactions (#75) each add their part of the cascade when they land.
8. **Where it lives**: `users`, `relations`, `images` packages (`Routes.kt`, `Service.kt`, `Repository.kt`); `/api/search` gets its router here, with the `users` branch only.

### Out of scope

- `/api/users?action=by-anonymizable-ids` and the `anonymizable_id` column → #77.
- The « Voir mes contributions » link (inventaire.io's website, per username) → to revisit with #77: contributions made through federation are filed under `acct`.
- Groups in `/api/search` → #72. Entity types → #76.
- Image resizing.

## Acceptance criteria

- Signed in, `GET /api/user` returns the account in the shape of inventaire.io's fixture; signed out → `401`.
- `PUT /api/user` with `bio`, `language`, `position`, `picture` → `GET /api/user` returns the new values.
- `PUT /api/user` with `username` taken → the refusal inventaire.io sends; free → renamed.
- `PUT /api/user` with `email` → the address shows unconfirmed and a confirmation e-mail is in Mailpit.
- `PUT /api/user` with a notification setting or `fediversable` → stored, returned by `GET /api/user`.
- `GET /api/users/by-ids?ids=a|b` returns both readers' public fields, never an e-mail.
- `GET /api/search?types=users&search=oliv` finds `OlivierB`; `types=users|works` → `400`.
- Relations: A requests B → B's `otherRequested` holds A; B accepts → both `friends`; A unfriends → neither; A requests, then cancels → nothing left; B discards A's request → nothing left; A requests B while B has requested A → friends.
- `POST /api/images/upload?container=users` with a JPEG → `/img/users/<hash>`, and that path serves the same bytes.
- `GET /api/images/gravatar` → a gravatar.com URL built from the address.
- `DELETE /api/user` → `{"ok":true}`; the reader's session, relations and avatar are gone; signing in again fails.
- iOS debug build on the local backend: Modifier le profil saves photo, bio and position; Réseau › Amis finds a second account, sends a request, the second account accepts it, both see each other as friends, Profil d'un ami opens; Supprimer mon compte ends on the welcome screen.
- The same journeys on Android, except deletion if Android lacks it.
- Each route has a backend test against a fixture captured on inventaire.io.
