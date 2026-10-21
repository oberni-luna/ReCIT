# 0037 — A Recherche tab, and what my friends just shelved

Shipped on 2026-10-21 from PRD `docs/prd/0020-search-tab.md` (deleted — see `docs/prd/README.md`),
in three issues, 0115 to 0117, after a grill the same day. No mockup. It takes back part of
[0014 — unified search, in the inventory screen](0014-unified-inventory-search.md): what the search
answers is unchanged, where it lives is not.

## What it does

**The search has a tab of its own again**, with the system's search role: iOS 26 sets it apart at
the end of the bar, as a magnifying glass in its own pill. The inventory has no search field any
more. There is still only one field in the app; it is where every other app puts it.

**Selecting the tab leaves the keyboard down**, because the tab has something to show before
anything is typed: the last three searches, then **« Chez mes amis »**, the ten books my friends
added last, in the very cards « Ranger mes livres » uses for books waiting to be filed. Past ten,
« Tout voir » lists them all. A reader with no friend sees a paper tag, « Trouver des lecteurs »,
that takes them to the Réseau tab. Friends with no book yet draw nothing.

**The carousel is discovery, not an answer.** It leaves at the first character typed, in the same
movement as the sections that replace it; from there, my friends' copies answer where they always
did, next to mine in « Dans mes livres et chez mes amis », and the three ways on to inventaire.io
follow.

**Nothing resets on leaving the tab.** The query, the results and a book opened from them are still
there on the way back, and inventaire.io is not asked again. Tapping Recherche while it is already
showing goes back to its root and raises the field; so does the empty shelf's « Rechercher » tag,
from the inventory.

## Technical surface

- **`SearchPhase`** — `current(query:submittedQuery:)` no longer takes the focus and never returns
  `nil`: an empty field is the rest state, keyboard or not. Two tests replace the two about focus.
- **`FriendsCarouselState`** (`Model/SearchResult/`) — pure: `hidden`, `invitation`, or
  `recent(shownCount:showsSeeAll:)`, from the phase, whether I have a friend, and how many books my
  friends have. Rest only; ten at most; « Tout voir » strictly past ten. Seven tests.
- **`TabRouter`** (`Features/MainNavigation/`) — `@Observable @MainActor`, owned and injected by
  `MainTabView` like `ShelfFocusModel`. It holds the selected tab (written through `select(_:)`, so a
  tap on the tab already showing is seen), a consumable `wantsSearchField` flag, a
  `searchRootRequest` counter, `openSearch()` and `openNetwork()`. Seven tests.
- **`MainTabView.TabConfig.search`** with `role: TabRole?` — both deleted at issue 0074, both back.
  Keys `tab.search` and `nav.search` restored.
- **`SearchTabView`** (`Features/Search/`) — the tab's root: its own `NavigationStack` and path,
  `.searchable(isPresented:)`, the submission and `.onSubmit(of: .search)`, moved as is from
  `ShelvesView`. It consumes the router's field request on appearing as well as on change, because
  the first request is usually the one that builds the tab.
- **The search screens moved** from `Features/Inventory/InventorySearch*` to `Features/Search/Search*`.
  Catalogue keys `inventory.search.*` and `e2e.*` identifiers are unchanged.
- **`SearchFriendsSection`**, **`FriendsCarouselCover`** (wraps `SortBookCardView`),
  **`SearchFriendsInvitationTag`**, **`FriendsLatestBooksView`** behind the new
  `NavigationDestination.friendsLatestBooks`.
- **`SearchContent`** animates its list on the phase's *step* (rest, typing, suggesting, results), not
  on the phase, which carries the query: a keystroke that only refilters is not animated.
- **End-to-end** — `E2EDriver.Tab.search`, whose root marker is the tab button selected with no back
  button reachable (every list tab carries a search field, so nothing on the root is unique to it).
  Each search selects the tab and walks it back to its root; leaving a search is opening the
  inventory.

Nothing new is persisted and nothing writes to the server; ADR 0001's optimistic path is not
involved.

## Notable decisions

- **The carousel was meant to stay while typing, and the spike killed it** (issue 0115). Filtered on
  the query and shrunk to a compact size, it was to sit between my books and inventaire.io. Two
  things went wrong: three local rows already reach the keyboard's edge (~516 pt on an iPhone 17), so
  inventaire.io started around 684 pt even with a compact carousel; and going back from three
  characters to two removed the local section and left the friends' carousel alone on screen, which
  the owner caught on a recording. The local section kept mixing my books and my friends'.
- **The cards are `SortBookCardView`, as is** — the first hand-made cell spaced its covers too far
  apart. Same width (`SortGridMetrics.bookColumnWidth`), same spacing, title under the cover, no
  owner avatar; VoiceOver names the owner.
- **Cards wait for the row's width.** Laid out at zero on the first pass, a cover was decoded by
  `CachedAsyncImage` for a zero-sized frame and never asked again — every cover came out blurred.
- **The empty recent-searches state only shows when there is nothing else**: with the carousel or its
  invitation on screen, a rest state saying "nothing here" would contradict itself.
- **The invitation changes tab** rather than pushing a screen: finding readers already has a home.
- **A flag, not an event, for the field.** The search tab may not exist yet when the empty shelf asks
  for its field; a flag waits for it.

## Owed, and known

- **`scripts/e2e.sh` has not been run against this.** `ReCIT_iOSE2E` builds with the rewritten
  steps; the run is the owner's (issue 0118).
- **Seen on the iPhone 17 simulator only**, signed in, with a friend holding more than ten books.
  Never on an iPhone SE, never with the software keyboard up (that simulator would not show it).
- **Not seen at all**: the empty shelf's « Rechercher » tag (the account has étagères), the
  invitation (it has a friend), the carousel filling during a friend's first sync, VoiceOver. The
  first two are covered by `TabRouterTests` and `FriendsCarouselStateTests` only.
- **Re-tapping Recherche is only reachable from a pushed screen.** While the search tab is active,
  iOS 26 folds the other tabs into one button and the magnifier becomes the field; the full bar —
  and the magnifier as a tab — comes back on a pushed screen.
- **One or two characters show nothing** — recents only draw at rest. Kept from 0014; with the
  carousel leaving at the first character, it deserves a look on a device.
- **Clearing the field from the results jumps once**: the local section leaves in a single frame.
  Not part of the spike's criteria, left alone.
- **Figma** — D-R6 in `docs/design-system/figma-library.md`: no tab bar with the detached search
  pill, no frame for the carousel or its invitation.
- **Android** (`Recit_Android/`) followed in [0041](0041-android-catches-up-with-ios.md).
