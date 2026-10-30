# A friend's profile: their picture at the head, their étagères, Inventaire | Listes

Shipped on 2026-10-30, on the branch `android-1.7.0`, in an autopilot run: three slices (PRD 0031, issues 0152
to 0154, deleted since). It reshapes the profile of [0018](0018-reader-network.md) and
[0019](0019-a-friends-shared-shelves.md), and opens the lists of [0060](0060-list-cover-flow.md) to friends.
Mock-ups: Figma `S7IvC6GvlcUFe5IgbtvQq6`, section « Détail d'un amis » (`865:17783`), frames F1 to F5.

## What it does

The profile no longer opens under a navigation title that repeats the name. It opens on the reader:

- **a header, centred** — their picture at 96 pt (the person glyph on a grey disc when they have none), their name
  in `title50`, how many books they hold, their bio. The bar keeps the way back and « … » (remove from the
  network, report) and shows no title;
- **their étagères**, the carousel of 0019 unchanged, absent when they share none (F4);
- **two tabs, Inventaire | Listes**, opening on Inventaire. Once the header and the étagères have scrolled away,
  the tabs **stay pinned under the navigation bar**, on the screen's ground, and the tab's content scrolls under
  them (F3).

**Inventaire** is the list the profile always showed: the first-sync bar while the books arrive, the books as they
come, « Emprunter à … » on a long press. Its header « Inventaire de X » went: the tab says it.

**Listes** shows the lists the friend lets me see, with the rows of my own Lists tab — covers fanned out, name,
what it is for, how many works or authors — and a chevron. Nothing writes: no « + », no swipe to delete, no
search. With no list it says « X n'a pas encore de liste » (F5); with none stored and the fetch failed, that the
lists could not be loaded; while the first fetch runs, a spinner.

**A friend's list opens on the same cover flow, read-only**: no « Modifier » in the bar, no add bar (the tab bar
stays in its place), no « Déplacer », no « Retirer de la liste ». Their comment, when they wrote one, reads as text
under « Commentaire », above the day the element was added.

On my own profile (reached from a transaction, say) the same screen shows my lists, which open editable.

## Technical surface

**A list knows its creator** (issue 0152). `EntityList` had no owner, and every list in the store was mine because
only mine were ever synced. It now carries `creatorId: String?`, from the listing's `creator`. A new optional
attribute: SwiftData migrates it lightly, with no plan. A list stored before has none, and **counts as mine** —
`EntityList.isCreated(byMe:)` — until my next sync stamps it.

- `ListModel.syncLists(forUser:)` still syncs mine; `syncFriendLists(of:)` syncs a friend's. Both go through one
  private sync whose **deletion pass is scoped** to the creator asked for (`upsert(scope:)`, the parameter 0019
  added for étagères): opening a friend's profile could otherwise have deleted every list of mine. Only my sync
  claims the unstamped lists. An answer without `creator` is stamped with the creator requested.
- **Mine only, wherever the app writes**: the Lists tab, the « … » menus (`EntityListMenu`), « Déplacer »
  (`ListMoveRow`) and the account-deletion count filter on `isCreated(byMe:)`.
- **Unfriending** deletes their lists at `reconcile`, next to their étagères, for the same reason: nothing syncs
  them again once the relation is gone.
- **The server decides what is visible.** `/api/lists/by-creators` answers with the lists I may see; nothing is
  filtered in the app.

`FriendListsTests` holds the five rules: the creator is stored, a friend's sync keeps mine (stamped or not) and
prunes theirs, my sync claims and prunes the unstamped, `isCreated(byMe:)`, and unfriending.

**The screen** (issue 0153). `UserDetailView` is a `ScrollView` over a `LazyVStack(pinnedViews: .sectionHeaders)`:
an inset grouped `List` does not pin its headers, and the tabs have to stay. Rows sit on cards of their own,
`CardRows` (`Features/Components/`), with a hairline between two — the book screen's and the forms'
`backgroundFormCell` on `backgroundForm`, corner radius `medium` as in the mock-up. The pieces:
`UserProfileHeader`, `UserItemCountText` (lifted out of `UserHeaderView`, which my Profil keeps),
`UserShelvesSection` (now a plain view, no longer a `List` section), `UserProfileTabPicker` over `UserProfileTab`,
`UserInventoryTab`, `UserListsTab`. `ThumbnailSize.xlarge` is 96 pt.

The title is set and then removed from the bar (`.toolbar(removing: .title)`), so the back button's long-press
menu still names the screen.

**A friend's lists are fetched each time their profile opens**, not in the launch's loop over friends: every
friend's lists would be fetched there, for a tab most profiles are never switched to. The store shows what it
holds in the meantime.

**Read-only** (issue 0154). `EntityListDetail` and `ListCoverFlowScreen` derive it from `isCreated(byMe:)`, as
`ShelfDetailView` derives it from the étagère's owner: a flag can be passed wrongly by a later caller, a list cannot
lie about whose it is. `ListReadOnlyCommentRow` shows their comment.

Five strings: `user.segment`, `user.lists.empty.title %@`, `user.lists.empty.message`, `user.lists.failed %@`,
`list.detail.comment.other`. `user.inventory.header %@` is no longer read.

## Decisions

- The lists live in the store, with a creator, like étagères — not in memory: the cover flow is built on
  `EntityList` and its `@Query`.
- An unstamped list is mine, rather than a migration that would have to guess.
- No name in the bar once the header has scrolled away: the request removed the title. The mock-up's spec leaves
  it as an open question.
- Cards on `backgroundForm`, not the system cell grey: a `ScrollView` has no cells, and the book screen already
  draws these.
- A non-friend's profile keeps its relation actions and « Inventaire privé », under the new header, with no tabs.

## Not done, not verified

- **Never seen running.** The simulator was signed out, and signing in to inventaire.io was not attempted. The
  header, the pinned tabs, the Listes tab, a friend's list read-only and the pressing of a book on an étagère
  inside a `ScrollView` (it lived in a `List` until now) all wait for a pass on a device or a signed-in
  simulator — in light and dark, with VoiceOver and the largest text sizes.
- **The e2e scenario** does not play this screen: it signs in to one account, and a friend's lists need two.
- **Android**: not ported; the Android app was being worked on in another session.
- The mock-up's avatar is a 48 px asset blown up to 96 pt.
