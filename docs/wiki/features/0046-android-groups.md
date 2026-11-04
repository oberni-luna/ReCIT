# Groups on Android

Shipped on 2026-10-24, from PRD 0025 and issues 0130–0132, in an autopilot run, on `main`; three
commits, one per issue. It ports iOS's groups — [0028](0028-network-tab-and-groups.md), the red dot
of [0033](0033-group-pending-dot.md), and the single gap under a group's header of
[0036](0036-inventory-authors-group-gap-press-lock.md) — to `Recit_Android/`, whose Réseau tab had
friends only since [0031](0031-android-app.md). The PRD and the issues were scaffolding and were never
committed; they were numbered past every number git history has seen, so as not to collide with the
deleted ones that feature docs still cite.

## What it does

**Amis | Groupes.** A segmented control sits in a band fixed under Réseau's large title, the same
for both segments; its ground follows the bar's as the title folds. The tab reopens on the segment
chosen last, Amis the first time. The « + » follows the segment: a reader to add, or a group to
start. Amis is the list the tab already had, unchanged.

**Groupes** lists, in this order:
- the invitations to join a group — who sent them, Accepter and Refuser under each;
- « Mes groupes », an « Admin » tag on mine and a red dot after the name of each group whose
  requests to join wait on me as its admin (TalkBack reads « 2 demandes à examiner »);
- « Demandes envoyées », the requests waiting on an admin;
- « Trouver un groupe » and « Créer un groupe ».

Before the first answer, a loading row; after a failed one, « Vos groupes n'ont pas pu être
chargés »; in no group, an empty state that says what a group is, with both ways in.

**The tab's badge** adds the group invitations and the requests waiting in my groups to the
friend invitations it already counted.

**A group's screen** is read afresh on every opening, mine or from the search. Its header:
- the picture as a rounded square — the groups glyph on the tinted fill without one, never a
  person's initials;
- the name, and the description, four lines then the rest on a tap;
- two tags, who may come in and how many are there.

Under it, what my place allows:
- *not a member* — « Rejoindre le groupe » when it is open, « Demander à rejoindre » otherwise,
  and the sentence that says which will happen;
- *request sent* — an inert button and « Annuler la demande »;
- *invited* — who invited me, Accepter, Refuser;
- *member* — nothing, unless I am the last admin of a group with members, which says why I cannot
  leave. The panel is left out rather than drawn empty.

An admin then sees the requests to answer, each with Accepter and Refuser. Five members follow,
« Voir les N membres », and « Inviter des amis » for any member. A member's « … » carries
« Réglages du groupe » (admins), « Inviter des amis » and « Quitter le groupe ». Leaving asks first,
and is greyed for the last admin of a group with members.

**The members** are listed by role: admins, members, requests to answer (admins only), invitations
sent. An admin has a « … » on each member's line — not on another admin's, nor their own — with
« Nommer admin » and « Retirer du groupe », each confirmed: neither can be undone from the app.

**Inviter des amis** lists my friends, filtered as I type, each with where they stand:
« Inviter », « Invitation envoyée », « Déjà membre », « A décliné ». A friend who had asked to join
gets « Accepter », since the server turns that invitation into an acceptance.

**Trouver un groupe** searches the visible groups by name, 350 ms after the last keystroke, in the
server's order; a row opens the group, and a group I already stand in carries its tag.

**Creating** is a sheet: a name checked as typed, 1 to 80 characters once trimmed, a description,
« Visible dans la recherche » (on) and « Ouvert à tous » (off). The button waits for the server;
a refusal is said under it; a success closes the sheet onto the new group.

**Settings** are a sheet too: the switches write as they move, the name and the description on
« Enregistrer », the group's address under the fields.

## Technical surface

- **`data/groups/`** — `ReaderGroup` (the five role lists, `role(of)`, `requestsToReview(by)`,
  `canLeave`, `everyoneIds`, `applying(action, by, on)`), `GroupMembership` (also the wire shape),
  `GroupRole`, `GroupAction` (with its path), `GroupSetting` (its wire value a `JsonPrimitive`),
  `GroupTransitionError`, `GroupSearchResult`, `MyGroups`, `GroupNameRule`, `GroupRequestLedger`
  with `PreferencesGroupRequestLedger`, and `GroupPeople`.
- **`data/GroupRepository.kt`** — every group read this launch in a `StateFlow` map by id;
  `myGroups`, `pendingCount`, `hasLoaded`, `observeGroup`; `syncMyGroups`, `fetchGroup`,
  `searchGroups`, `perform`, `createGroup`, `update`, `reset`. Built in `AppContainer`.
- **`network/dto/GroupDtos.kt`** — `GroupDto`, `GroupsDto`, `GroupByIdDto`,
  `GroupSearchResultsDto`, and the three payloads.
- **Endpoints**, checked against iOS, which checked them against the live OpenAPI spec:
  - `GET /api/groups` — admin, member or invited, never requested;
  - `GET /api/groups/by-id` — the group and its people as users;
  - `GET /api/search?types=groups`;
  - `POST /api/groups`;
  - `PUT /api/groups/<action>`;
  - `PUT /api/groups/update-settings`.
- **Sync** — `SyncStatus.Domain.Groups`, right after the relations in `SessionCoordinator`, as
  on iOS since 0035; signing out and deleting the account call `groups.reset()`.
- **Users** — `UserRepository` implements `GroupPeople`: `store(users)` upserts the people a
  `by-id` answer carries, `fetchMissing(ids)` fetches the rest by fifty; `observeUsers(ids)` reads
  them through a new `UserDao.observeMany`. No schema change.
- **`ui/network/`** — `NetworkSegment` (the enum, `restored`, `NetworkSegmentBand`);
  `NetworkScreen` keeps the bar, the band and the refresh, its friends' list moved to a private
  `FriendsSegment`; `UserPreferences.observeString` reads the remembered segment.
- **`ui/network/groups/`** — `GroupsSegment`, `GroupScreen`, `GroupMembersScreen`,
  `FindGroupsScreen`, `InviteToGroupScreen`, `CreateGroupSheet`, `GroupSettingsSheet`,
  `GroupViewModel`, the rows and tags of `GroupComponents`, and the pure `GroupLogic` and
  `GroupsSegmentState`.
- **`Destination`** — `Group(id)`, `GroupMembers(id)`, `FindGroups`, `InviteToGroup(id)`.
- **Strings** — `strings_groups.xml`, French, keys `groups_*` and `network_segment_*`; the iOS
  plurals stay plurals.
- **Tests** — 349 JVM tests, up from 307: `ReaderGroupTest` (13), `MyGroupsTest` (4),
  `GroupRepositoryTest` (18, against MockWebServer with an in-memory ledger and a recording
  `GroupPeople`), `GroupFormsTest` (3), `GroupsSegmentStateTest` (4).

## Notable decisions

- **In memory, not in Room.** A table would be a schema migration (version 1 to 2), which the
  project does not make without asking; iOS made the same call in 0028 and only persisted its groups
  in 0035, for the graph. The groups are read again at every launch, and the segment spins until
  they are. The people in them are users of the store.
- **A group the sync stops naming stays readable**, as the server now has it, without me: a screen
  open on a group I left on the website does not go on offering « Quitter ». A request whose
  read-back failed is kept as it was.
- **The requests I sent are kept per account in the preferences** (`groups.requested.<user id>`),
  since `GET /api/groups` leaves them out; each sync reads them back with `by-id`. A 404 forgets one.
  A request made on the website is not known here until it is answered.
- **The server's transitions, replayed.** `ReaderGroup.applying` reproduces
  `groupMembershipActions`, shortcuts included, so every gesture is optimistic through the
  `OptimisticRunner` (ADR 0001). A gesture the server would refuse is reported and neither shown
  nor sent; `GroupTransitionError` carries no message, so the snackbar says « Une erreur s'est
  produite » and no English.
- **Creating is not optimistic**: creations are rate-limited and spam-checked, the slug is the
  server's, and the screen that follows needs the id.
- **The segment is remembered across launches**, as iOS's is; the band shows Amis for the frame
  before the preference is read.
- **No graph.** iOS's « Tout » is compiled in `DEBUG` only, pending its device review.
- **`NetworkScreen.kt` carried uncommitted work of the owner's** (`LargeTitleRefreshBox`). Its edits
  were applied to the committed version and to the working copy alike, so the commits hold only the
  groups, and the working copy holds both.

## Not done, not verified

- **Never seen signed in, nor even launched.** Built, the JVM suite green, the commits built and
  tested again on their own in a clean worktree, without the uncommitted changes. Nothing has been
  drawn with a real account: the band under a folding title, the dot beside a name that wraps, the
  sheets with the keyboard up, the menus, dark mode, and TalkBack throughout.
- No end-to-end scenario or instrumented test exists for Android.
- Not ported, as on iOS: a group's books, its picture and place, inviting by e-mail, reporting a
  group, sharing an étagère or a list with a group. Not ported from iOS: the « Tout » graph, and the
  persistence of 0035.
- No Figma pass.
