# 0041 — Android catches up with iOS: authors, À propos, the avatar, Recherche, black

Shipped on 2026-10-21, on autopilot, from PRD 0021 and issues 0119 to 0123, all deleted with this
write-up; five commits, one per issue. The request was the owner's, in a sentence: port to
`Recit_Android/` every recent iOS change. "Recent" was read as everything since the Android port
of 2026-10-02 (feature 0031) — features 0032 to 0040 — that touches a surface Android has.

## What it does

**Every book of « Tous les livres » names its authors** (iOS 0036). Android had the same gap as
iOS: an edition first met as an entity, through the search or the book screen, carries no author
names, and the item's snapshot only built an edition when the store had none. The snapshot now
fills the names in whenever it names somebody. Until then, a row names the authors of the
edition's works, sorted. A row with no name at all still draws no author line.

**The Profil says what inventaire.io is, and the version** (iOS 0034, without the donations).
- A row « À propos d'inventaire.io », under the account, pushes a white screen. On it:
  - my three latest books standing on a plank, inventaire.io's paper tag under it;
  - « La bibliothèque derrière Ex-libris » and its tagline;
  - four value rows, each glyph in a pale green disc;
  - « Aller plus loin », four links outlined by a hairline, opened in the browser;
  - the app's icon as a tile, and the independence note.
- The Profil's last line reads « Ex-libris · Version 0.1.0 (1) ».
- The paper tag of feature 0026 is gone.

**The Profil leaves the tab bar, behind my avatar** (iOS 0038).
- A round button sits at the top left of Inventaire, Listes and Réseau. It is the account's
  picture when there is one, over the old tab's person icon.
- It opens the profile at full height over the tabs, sliding up from the bottom. What the profile
  pushes stays inside it.
- « Fermer » at the top left closes it. The system back pops inside it first, then closes it.

**A Recherche tab, and « Chez mes amis »** (iOS 0037, and 0040's field).
- The search leaves the inventory for a last tab. Its field is always shown under the title, and
  the keyboard stays down on arriving.
- At rest, the tab shows the last three searches, then my friends' ten latest books as cover cards,
  with « Tout voir » past ten. A reader with no friend sees « Trouver des lecteurs », a paper tag
  that selects Réseau. The row leaves at the first character typed.
- Tapping Recherche while it shows sends it back to its root and raises the field. The empty
  shelf's « Rechercher » does the same, from the inventory.
- Leaving the tab keeps the query and its results.

**Black behind the tabs' lists in dark** (iOS 0039, and 0040's list detail).
- Listes, a list's detail, Réseau and Recherche sit on black, with grey cells. The Profil sits on
  `gray/900`, its cards in the same grey.
- Recherche's sections are inset cards; « Chez mes amis » runs edge to edge.
- In light nothing changes.

## Technical surface

- **Authors.**
  - `Merges.authorNames(snapshot)` reads `entity:authors` once.
  - `Merges.withSnapshotAuthors(edition, snapshot)` merges the names, called from
    `InventoryRepository.upsertItem`.
  - `ItemRow` gains a second relation to its edition, `EditionWorkAuthors`, which holds the works
    with their authors. `ItemRow.authorNames` is now the displayed list, from
    `ItemRow.displayedAuthorNames`.
  - No Room schema change.
- **À propos.**
  - `Destination.AboutInventaire` leads to `AboutInventaireScreen`, with `AboutInventaireViewModel`
    supplying my three latest copies.
  - `StandingCover` (now with an optional `onClick`) and `Plank` in `ShelfCarousel.kt` are now
    internal.
  - `AppIconTile` restates the icon's gradient.
  - `drawable-nodpi/inventaire_io.png` and `books_on_shelf.png` are copied from the iOS assets.
  - Strings `about_*`, `profile_about_inventaire`, `profile_version`. `BoldMarkup` and its test
    went with the paper tag, its only user, along with `profile_inventaire_*` and the preference key.
- **Avatar and sheet.**
  - `TabRouter` (`ui/navigation/`) is plain Compose state, saved with a `Saver`, handed down by
    `LocalTabRouter`. It holds `selected`, `select(tab)` (true on a reselection),
    `isProfilePresented`, `openProfile()` and `closeProfile()`.
  - `ProfileAvatarButton` and `ProfileSheet` (`ui/profile/`). The sheet is an `AnimatedVisibility`
    overlay in `MainScaffold` with its own `NavDisplay` from `Destination.ProfileRoot`, and its own
    snackbar host while it covers the shell's.
  - `AppTab.Profile` and `tab_profile` are deleted. `RecitLargeTopBar` takes a `navigationIcon`.
- **Recherche.**
  - `AppTab.Search` with `Destination.SearchRoot`.
  - `SearchScreen` and `SearchViewModel` take over the search half of `InventoryScreen` and
    `InventoryViewModel`. The field is a collapsed Material 3 `SearchBar`.
  - `TabRouter` also carries `wantsSearchField` (consumed once by `consumeSearchField()`),
    `searchRootRequest` (the shell pops the Recherche stack on it), `openSearch()` and
    `openNetwork()`.
  - `SearchPhase.current(query, submittedQuery)` no longer takes the focus and never returns null.
  - `FriendsCarouselState` and `FriendsCarouselMetrics` are pure. The metrics are iOS's
    `SortGridMetrics` book column.
  - `SearchFriendsSection.kt` and `FriendsLatestBooksScreen` (`Destination.FriendsLatestBooks`).
  - The search files moved from `ui/inventory/` to `ui/search/`; `InventorySearchContent` is now
    `SearchContent`. String keys keep their `inventory_search_` prefix, as the iOS catalogue does.
- **Black.**
  - Tokens `backgroundGrouped` (`gray/50`, `gray/1000`), `backgroundGroupedElevated` (`gray/50`,
    `gray/900`) and `backgroundGroupedCell` (`gray/0`, `gray/800`).
  - `RecitLargeTopBar` and `RecitTopBar` take a `containerColor`; `SectionCard` takes a `color`.
  - A private `groupedCell` modifier in `SearchContent.kt` rounds a section's ends.
- Tests: 113 JVM tests, up from 101.
  - New: `TabRouterTest` (7), `FriendsCarouselStateTest` (7), three in `MergesTest`.
  - Removed: `BoldMarkupTest`.
  - Rewritten: two tests of `SearchPhaseTest`.
  - Moved: the inventory's tests that sat in the search suites now live in `ShelfLogicTest`.

Nothing new is persisted and nothing new talks to the server.

## Notable decisions

- **Only what has an Android surface.** Three changes were left out, because what they change was
  never ported:
  - « Enregistrer » and the question before leaving the sorting (0032);
  - the group's red dot and the gap under a group's header (0033, 0036);
  - the press that locks halfway (0036).
- **No donations.** The café card and the donation sheet would need Play Billing, a new dependency,
  and products on the Play Console. À propos and the version were ported without them.
- **An overlay, not a `ModalBottomSheet`.** A sheet window hosting a Navigation 3 stack, with its
  back handling on top, was the riskier of the two. The cost is that the sheet cannot be swiped
  down.
- **A third token for the cells.** iOS cells take the system's grouped grey. Android's were
  `backgroundDefault`, which is black in dark and would have vanished on the new black. `gray/800`,
  the old background, is the cell. In light all three tokens hold their previous values.
- **No avatar on Recherche**, as on iOS: the request named three screens.
- **The carousel's card is a port of `SortBookCardView`**, at the same width and spacing. Android
  has no sorting surface, so the card lives with the search.
- **The version stays 0.1.0 (1).** iOS went to 1.4.0 for a release; Android has not shipped.

## Not done, not verified

- **Never seen signed in**, like everything Android since feature 0031. The app was built,
  installed and launched on the Pixel 8 API 35 emulator, signed out, and showed the welcome screen.
  None of the five changes is visible without a session; a pass on a device with a test account is
  owed. In particular:
  - the authors on real rows;
  - the À propos shelf with real covers;
  - the avatar with a picture;
  - the sheet's slide and back handling;
  - the carousel's cards;
  - the inset cards in dark;
  - TalkBack throughout.
- **No end-to-end scenario or instrumented test** exists for Android.
- **Not ported:** donations; and, as before (feature 0031), the scanner, sorting, groups,
  transactions and the full-screen cover.
- No Figma pass.
