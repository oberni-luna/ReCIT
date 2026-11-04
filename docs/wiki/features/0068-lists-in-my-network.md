# Lists in my network, in the Lists tab

Shipped on 2026-10-31, on `main`, in an autopilot run: a single slice, with no PRD or issue files. Mock-ups:
Figma `S7IvC6GvlcUFe5IgbtvQq6`, section « Listes » (`735:22155`): `N1 · Listes · Mes listes et Dans mon réseau`
(`891:826`), `N2` in dark (`892:1067`), `N3 · Listes · Aucune liste à moi` (`892:1163`), and the
`Spec · Listes · Dans mon réseau` panel (`892:1264`). It builds on the friends' lists of
[0064](0064-a-friends-profile-with-tabs.md), which were stored only for a friend's profile.

## What it does

- **Two sections in the Lists tab.**
  - « Mes listes » (« My lists »): mine, by name.
  - « Dans mon réseau » (« In my network »): every friend's lists, the most recently changed first, which is
    what they have just done. A list never changed counts from the day it was made.
  - The headers show only when the network has lists; otherwise the tab looks as it did.
- **A friend's row** opens the list read-only. `EntityListDetail` already knew a list that is not mine. A
  friend's row has no swipe to delete.
- **Every row opens on a line above its name.**
  - The line holds the count. For a friend's list it starts with their picture (16 pt, round) and their name:
    « Léa • 14 œuvres ».
  - Then the list's name, then what it is for, on up to three lines (one before).
  - Their profile's Listes tab uses the same row.
- **The search** filters both sections by name. A section with nothing left goes.
- **Empty states**:
  - nothing on either side: the empty screen as before;
  - nothing in the network: the tab as before;
  - none of mine while my friends have some: « Mes listes » keeps one tinted row, « Créer une liste », which
    opens the same form as the « + ».
- Only readers whose relation is `.friend` count. A stranger's lists, stored when their profile was opened,
  stay on that profile, and an unfriended reader's lists leave with the relation as before.

## Technical surface

- **The sync.** `ListModel.syncNetworkLists(of:modelContext:)` fetches every friend's lists through
  `/api/lists/by-creators?users=a|b|…&with-elements=true`.
  - It asks for 50 friends per request and runs in `UserDataSync` right after my lists and transactions,
    before the friends' books, which take minutes.
  - It is outside the `SyncStatusStore` tracking: the tab's placeholder still waits on my lists alone.
  - It makes no request without friends.
- **The pruning.** The private `syncLists(createdBy:)` now takes a set of creators and limits its deletion
  pass to them. Asked about several readers, it drops any list in the answer that names no creator, because
  stored unstamped it would pass for mine (`isCreated(byMe:)`). A single reader's sync still stamps such a
  list from the request.
- **The sections.** `ListsTabSections` is pure: from the stored lists, my id, my friends and the search text,
  it returns `mine` and `network` (`NetworkListEntry`: a list and its owner). The view computes it twice:
  - unfiltered, for the empty screen and the headers;
  - filtered, for the rows.
- **The view.** `ListsTabList` draws the two sections. `EntityListView` keeps the placeholder, the empty
  screen, the toolbar and the search.
- **The row.** `ListRowView(list:owner:)` uses `ListRowMetaLine`: `AvatarThumbnail` at a `@ScaledMetric` 16 pt,
  the name, « • », the count, all in `caption200` and `foregroundSecondary`.
- **New text style:** `TextStyle.content200`, Alegreya Medium 15, scaled from `.subheadline`. It is the
  Figma `Content/content200` that the mock-up's explanation uses.
- Two strings: `lists.section.mine`, `lists.section.network`. « Créer une liste » reuses
  `lists.empty.action.create.title`.

## Decisions

- **Order**: the spec left « by friend, then by name » open, and this run took the most recently changed
  first.
- **No limit and no « Tout voir »**: every list of every friend shows.
- One request for every friend rather than one per profile. `by-creators` was checked live to accept ids
  joined by `|`.

## Tests

`NetworkListsTests`:
- one request for two friends;
- none without friends;
- the pruning spares mine, my unstamped ones and a stranger's;
- an unattributed list is dropped;
- the sections' order and owners;
- the search in both sections.

The whole `ReCIT_iOSTests` target passed (1,219 tests, the gated integration test skipped).

## Not done, not verified

- **Not seen signed in.** The simulator was signed out, and this run does not type passwords into
  inventaire.io. The rows were rendered through `ImageRenderer` in light and dark, and match N1. Not seen:
  - the sections in a real `List`;
  - the headers;
  - the « Créer une liste » row;
  - the search;
  - the largest text sizes;
  - VoiceOver.
- `by-creators` may page its answer. A friend group with many lists may come back short; the call sends no
  `limit`, as my own lists' sync never has.
- **The e2e scenario** does not play this section: one account, no friend.
- **Android**: not ported.
- A 16 pt avatar without a picture shows its ground without initials.
