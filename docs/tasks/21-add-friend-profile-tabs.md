---
issue: 21
status: todo
wiki: [[features/0064-a-friends-profile-with-tabs]], [[features/0066-a-friends-profile-tabs-as-pages]], [[features/0067-a-friends-profile-presentation-tab]], [[features/0031-android-app]], [[features/0041-android-catches-up-with-ios]]
note: split from #20; sprint Android 1.3.0 — Android catches up with iOS 1.9.0
created: 2026-11-04
---

## Context / Decisions

> Inventaire, Listes, Présentation as swiped pages. Split from #20 on 2026-11-04.

- **Goal:** the Profil d'un ami on Android matches iOS 0064, 0066 and 0067.
- **Branch:** #21, #22 and #23 are coded and committed straight on `sprint/android-1-3-0`, one commit per task, no task branch, no task PR (Olivier's call, 2026-11-04). Board cards are moved by hand.
- **Room:** `AppDatabase` goes from version 1 to 2 by `AutoMigration(from = 1, to = 2)`. Android 1.2.0 shipped schema 1, so the local cache must survive the update. `schemas/…/2.json` is exported and committed.
- **List creator model (built here, reused by #22):**
  - `EntityListEntity.creatorId` (nullable), read from `ListDto.creator`.
  - `isCreatedByMe`: no creator stamped, or creator = the signed-in user.
  - `ListRepository.syncLists` deletes only lists missing from the answer *among the creators it asked for*; it never deletes a friend's list when syncing mine.
  - A friend's lists are fetched when their profile opens, and deleted when the friend is removed.
  - « Mine only » filters: Lists tab, the book's « … » menus, the move-to-list row, the account-deletion count.
- **Read-only list:** a friend's list opens in `EntityListScreen` with no add bar, no swipe to remove, no edit; their comment shows as plain text.
- **Header (decided: full iOS fold):** picture 96 → 48 pt into the bar's row, name `title200` → `title50`; the header snaps, never rests half folded; the bar's backdrop and hairline appear only once folded; the fold follows the page on screen.
- **Tabs:** a simple sliding capsule (not 0075's lens, a later task), replacing `NetworkSegment`'s M3 `SegmentedButton` on this screen only. Tabs: « Inventaire • 540 », « Listes • 4 », « Présentation »; the count line under the name goes.
- **Pages:** `HorizontalPager`, one page per tab, each keeping its own scroll; the capsule follows the finger during a swipe.
- **Présentation:** `bio` added to `UserDto` / `UserEntity`; shown in a selectable card; empty → « X n'a pas encore écrit de présentation ».
- **Étagères** move under Inventaire only.
- **Closed profile** (not a friend): a single page, bio centred on top, no tabs.
- **Wording:** every string copied from the iOS screens (0064, 0067), French.
- **No Wikidata**, no lens: out of scope.

## Acceptance criteria

- [ ] Open a friend's profile: header shows a 96 pt picture and the name; tabs read « Inventaire • N », « Listes • N », « Présentation »
- [ ] Scroll Inventaire: header folds to a 48 pt picture in the bar row; releasing mid-fold snaps open or closed
- [ ] Swipe left/right between the three pages; each page keeps its scroll position; the capsule tracks the finger
- [ ] Inventaire page shows the friend's étagères above their books; Listes page shows their lists with Lists-tab rows
- [ ] A friend with no list → « X n'a pas encore de liste »; no bio → « X n'a pas encore écrit de présentation »
- [ ] Tap one of the friend's lists → opens read-only: no add bar, no swipe to remove, comments as text
- [ ] My Lists tab, the « … » menus and the move-to-list row never show a friend's list
- [ ] Profile of a non-friend: one page, bio centred on top, no tabs
- [ ] Update from 1.2.0 over an existing install: app launches, my books and lists still there (AutoMigration 1→2)
- [ ] Remove a friend: their lists vanish from the store
- [ ] Unit tests: `syncLists` scoped deletion, `isCreatedByMe`, migration 1→2 (`MigrationTestHelper`)
