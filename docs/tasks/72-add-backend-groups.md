---
issue: 72
status: to-test
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

## Implementation

stacked on: wa/71-add-backend-users-and-friends @ 5f7b45e

- **Migration `V4__groups.sql`:** `groups` (unique slug, trigram index on `lower(name)`) and `group_memberships`, one row per reader and group (role admin | member | invited | declined | requested, invitor, timestamp).
- **Package `groups`:** `GroupsRoutes`, `GroupsService` (read, create, update-settings), `GroupMembershipService` (the ten actions, `leaveAll`), `GroupsRepository`; pure rules `MembershipRights` (from `membership_validations.ts`) and `MembershipMoves`; `GroupSlug`; answer documents. `users/UserDocumentsService` lifted out of `UsersService` and shared by `by-ids` and the group `by-id`.
- **Changed elsewhere:** `ImageContainer` gains GROUPS, `/img/<container>/{hash}` for every container, `releasePicture(path)` for any container; `RelationsService.network` = friends + group co-members (`networkIds` replaces `friendIds`); `/api/search?types=groups`; `UsersService.deleteAccount` leaves every group first.
- **Apps unchanged** on iOS and Android.
- **Differences from the spec and from inventaire.io:** the apps and inventaire.io send **PUT** for the ten actions and `update-settings` (the spec said POST), so PUT is served; no spam check or creation limit; no group notifications; `_score` is pg_trgm similarity; `by-slug`, `slug` and `search-by-position` not served (the apps never call them). Kept from inventaire.io: « membership already exist » answers 200 with an error body; accept-request on someone who did not ask → 401; slugs keep letters only, a second group of the same name gets `.1`; account deletion copies `leaveAllGroups` (the 3 most senior members become admins when none is left, an empty group is deleted with its picture); `position` and `invitor` written as `null`. `types=users|groups` together is accepted.
- **For #73/#74/#75:** `RelationsService.networkIds(userId)`; `RelationsRepository.groupCoMembersOf`; `GroupsRepository.groupsOf(userId, roles)` for `group:<id>` visibility; `UserDocumentsService.documents(ids, viewerId)`; `ImagesService.releasePicture(path)`; test helpers `groups/GroupClient.kt`. Next migration V5. A test that signs up more than 5 readers in one `testApplication` hits the 429.
- Fixtures: anonymous captures only (`by-id`, `GET /api/groups` signed out, `search?types=groups`, `/img/groups/…`); the rest derived from Codeberg. Local accounts in `Recit_Backend/.env.example`.

## Verification

- `./gradlew build`: 125 tests green, ktlint and detekt clean. iOS `ReCIT_iOSTests` green; Android build + 607 unit tests green.
- Every backend acceptance criterion replayed by curl (creation, invite/accept/decline, request/accept-request/refuse/cancel, make-admin, kick and its refusal on an admin, last-admin leave refused then allowed, last member leaving deletes the group, update-settings read back, search hides non-searchable groups, `network` lists a co-member, group upload served byte-identical, deleting a sole member's account deletes the group).
- **iOS, iPhone 17, local backend, as `exlibris_ios_70`:** the Réseau badge and the red dot of 0033 on « Club Ex-libris iOS »; Accepter the pending request (`PUT /api/groups/accept-request`, 2 membres); Réglages du groupe › Choisir dans Photos › Enregistrer (`PUT /api/groups/update-settings`, `/img/groups/…` served, photo shown); Inviter des ami·es › `exlibris_friend_71` (`PUT /api/groups/invite`); Supprimer le groupe (`by-id`, two `kick`, `leave`), « Aucun groupe pour l'instant »; Créer un groupe « Lecteurs du quartier » (`POST /api/groups 201`), its screen with ios_70 as admin.
- **Android, Pixel 8 API 35, local backend, as `exlibris_friend_71`:** the Réseau badge, the invitation to « Club Ex-libris iOS » with its new photo, Accepter (`PUT /api/groups/accept`, 3 membres); Trouver un groupe « Cercle » lists the searchable groups. The emulator ANR'd twice on start while the Mac's load was around 30, then ran normally.
