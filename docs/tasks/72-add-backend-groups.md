---
issue: 72
status: todo
wiki: [[network]], [[features/0028-network-tab-and-groups]], [[features/0033-group-pending-dot]], [[features/0056-deleting-a-group]], [[features/0082-a-groups-photo-from-its-settings]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #71 (users, relations, images). Group lists (#63) build on it later.
created: 2026-11-06
---

## Context / Decisions

> groups, group search, group photos
>
> Part of #62. /api/groups*, search types=groups, /img/groups/*.

Groups served as inventaire.io serves them, so Réseau › Groupes, a group's screen, Réglages du groupe and the red dot of 0033 work against the backend unchanged.

### Routes the apps call (read from `GroupAction.swift`, `GroupModel`, Android's groups repository)

- `GET /api/groups` (my groups), `GET /api/groups/by-id?id=…`, group creation as the apps send it
- `POST /api/groups/update-settings`
- `POST /api/groups/<action>` with `{group, user?}`: `invite`, `accept`, `decline`, `request`, `cancel-request`, `accept-request`, `refuse-request`, `make-admin`, `kick`, `leave`
- `GET /api/search?types=groups&search=…`
- `POST /api/images/upload?container=groups`, `GET /img/groups/<hash>`

### Decisions

1. **Same payloads as inventaire.io**, proven by fixtures captured there: a group carries `admins`, `members`, `invited`, `declined`, `requested`, each entry `{user, invitor, timestamp}`.
2. **Stored as one `group_memberships` row per reader and group** (role `admin` | `member` | `invited` | `declined` | `requested`, invitor, timestamp), serialized into those five arrays.
3. **Rights copied from inventaire.io** (`server/controllers/groups/lib/membership_validations.ts`):
   - admins only: `accept-request`, `refuse-request`, `make-admin`, `update-settings`, `kick`;
   - `kick` never targets another admin;
   - `invite`: any member, the invited reader must exist;
   - `leave`: the last admin cannot leave while other members remain, until they name another admin;
   - `request`, `cancel-request`, `accept`, `decline`: on one's own membership only;
   - refusals in inventaire.io's error shape and status.
4. **A group ends with its last member**: when the last one leaves, the group is deleted, as on inventaire.io. No deletion route: feature 0056's « kick everyone, then leave » keeps working. A real deletion can come with group lists (#63).
5. **Settings**: name (slug recomputed, unique, as inventaire.io does), description, `open`, `searchable`, picture, position — the ones `update-settings` receives today.
6. **Group search**: `pg_trgm` similarity on the name, `searchable` groups only, `types=groups` only (#62 decision 10).
7. **Group photos**: `POST /api/images/upload?container=groups` through `ImageStore`, answering `/img/groups/<hash>`, served by `GET /img/groups/<hash>` (a `<w>x<h>` path serves the original), as #71 does for avatars.
8. **`network` in `/api/relations`**: the readers who share a group with me, the list #71 left empty, filled here.
9. **Account deletion** (#71) leaves the reader's groups as `leave` would, and deletes a group left empty.
10. **Where it lives**: `groups` package (`Routes.kt`, `Service.kt`, `Repository.kt`); the `groups` branch of `/api/search`.

### Out of scope

- Group notifications (inventaire.io's `groupUpdate`, `userMadeAdmin`): the apps never call `/api/notifications`.
- A deletion route, group lists, group étagères.

## Acceptance criteria

- Creating a group → it appears in `GET /api/groups` with its creator as admin, and its slug in `by-id`.
- `invite` from a member → the invited reader sees it under `invited`; `accept` → member; `decline` → `declined`.
- `request` on a group → under `requested`; `accept-request` by an admin → member; by a plain member → refused; `refuse-request` → gone; `cancel-request` by the requester → gone.
- `make-admin` by an admin → admin; `kick` of a member by an admin → gone; `kick` of an admin → refused.
- `leave` by the last admin with other members → refused; after `make-admin` of another → allowed; `leave` by the last member → the group is gone from `by-id`.
- `update-settings` changes name, description, `open`, `searchable` and picture, read back from `by-id`.
- `GET /api/search?types=groups&search=…` finds a `searchable` group and never a non-`searchable` one.
- `GET /api/relations` lists a reader who shares a group with me under `network`.
- `POST /api/images/upload?container=groups` → `/img/groups/<hash>`, serving the same bytes.
- Deleting an account that was the sole member of a group deletes the group.
- iOS debug build on the local backend: create a group, invite a second account, accept from it, the admin's red dot for a request (0033), change the photo in Réglages du groupe (0082), Supprimer le groupe (0056) ends with the group gone.
- The same journeys on Android, as far as feature 0046 goes.
- Each route has a backend test against a fixture captured on inventaire.io.
