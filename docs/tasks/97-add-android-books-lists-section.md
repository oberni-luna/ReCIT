---
issue: 97
status: to-close
wiki: [[features/0079-the-lists-a-book-is-in]], [[features/0068-lists-in-my-network]], [[features/0077-android-catches-up-with-1-9-0]], [[features/0062-android-catches-up-with-1-7-0]]
note: Rattrapage iOS 1.10.0 (feature 0079). Friends' lists and elements are already in Room since 0077.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0079](../wiki/features/0079-the-lists-a-book-is-in.md), whole, arrival animation included (Olivier's pick).

- **Section « Dans les listes »** on the Fiche livre (`ui/book/BookScreen.kt`), between « Dans mon inventaire » and « Données bibliographiques ». One row per list of works holding one of the edition's works, drawn as the Lists tab's row (fanned covers, count, name, explanation); a friend's row starts its count line with their picture and name.
- **Whose.** Mine and my friends' (`creatorId`). A stranger's list in Room (profile opened) is left out; lists of authors are left out.
- **Order.** Mixed, most recently changed first (`updated ?: created`).
- **No list → no section**, no header, no empty card, no « Ajouter à une liste » row.
- **A recueil**: a list holding two of its works shows once and opens on the first of them in the list's order (lowest `ordinal`).
- **Data.** Reactive (ADR 0001): a Room query of the elements whose `uri` is one of `BookUiState.works` URIs, joined to their lists, plus the friends — an add or removal elsewhere updates the section. Nothing new goes to the server. No index or migration on `list_elements.uri` (volumes are small).
- **Pure rule, tested**: filter (mine/friends, works only), dedupe (focus = lowest ordinal), order — the iOS `BookListEntry.entries` as a Kotlin function with unit tests.
- **Opening.** `Destination.EntityList` gains `focusUri: String? = null`; a tap pushes it on the current tab, on its « Livres » page. A friend's list opens read-only, as from the Lists tab. Back returns to the Fiche livre at the same scroll position. The same list may be pushed twice; the stack is not inspected.
- **Arrival, as iOS.** The cover flow starts on the list's first book; ~300 ms later it scrolls in 0.4 s to the focused book (through `requestSelection`); once centred, its cover gets a halo in `foregroundTinted` (2 dp stroke 5 dp out + a 14 % 8 dp stroke 11 dp out) fading in over 1.2 s; one haptic on arrival; TalkBack focus moves to the book's title. Once per opening; a swipe or a touch elsewhere puts the halo out at once.
- **One haptic only.** The cover flow's page-change haptic must not also tick for the first selection on opening — on every list, as iOS.
- **Reduced motion** (system « Supprimer les animations », animator scale 0): the list opens directly on the book, the halo only fades.
- **Arrival state machine** (`waiting` → `arriving` → `highlighted` → `done`) pure and unit-tested, as iOS `ListArrivalFocus`.
- String « Dans les listes » (French only).

## Acceptance criteria

- A book whose work is in one of my lists and one friend's list: « Dans les listes » between « Dans mon inventaire » and « Données bibliographiques », two rows, the friend's showing their picture and name, the most recently updated first.
- A book in no list: no section, no header.
- A list of authors holding the book's author: not shown. A stranger's list (their profile opened before): not shown.
- Removing the work from my list elsewhere, then back to the book: the row is gone without reload.
- Tap my list's row: the list opens on « Livres », on its first book, then scrolls to the book, the halo fades in, one vibration.
- Swiping the cover flow right after: the halo goes out.
- With animations off in the system settings: the list opens directly on the book, halo fades in, no scroll.
- Tap a friend's list row: it opens read-only (no add bar, no remove), same arrival.
- Back: the Fiche livre at the same scroll position.
- Opening any list from the Lists tab: no vibration on opening.
- Unit tests: entries filter/dedupe/order; arrival state machine.

## Implementation

stacked on: wa/94-add-android-private-notes @ 83722e6

- Pure rules, `data/lists/`: `BookListEntry.entries(lists, workUris, myUserId, friends)` (mine or a friend's lists of works; a recueil once, focused on its lowest `ordinal`; `lastChanged` desc, then id) and `ListArrivalFocus` (Waiting → Arriving(Scroll|Jump) → Highlighted → Done, `landingFeedbackUri`, `jumpUri`).
- Data: `EntityListEntity.lastChanged` + `friendCreator(myUserId, friendsById)` (now also used by `ListsTabSections`, unchanged behaviour); `ListDao.observeHolding(uris)` Flow — no migration, no index; `ListRepository.observeListsHolding(uris)`.
- Fiche livre: `BookUiState.inLists` built reactively from the works' uris, friends (`observeByRelation(Friend)`) and `myUserId`, starts empty; `BookListsSection.kt` (`bookLists` + `BookListRow`), the Lists tab's `ListRow` drawn on `backgroundFormCell` with `ListRowDivider`; one line in `BookScreen` between `myCopy` and `bibliographicData`. `ListRowFeed` fetches missing preview covers, as the Lists tab — the only network traffic.
- Navigation: `Destination.EntityList(id, focusUri: String? = null)`; existing push sites untouched.
- Arrival: `EntityListViewModel(focusUri, reducesMotion)` with `arrival` StateFlow, `landArrival()`, `endArrivalHighlight()`; every selection change through `setSelection`, which puts the halo out; a jump selects the book with the first rows. `EntityListScreen.followArrival`: 300 ms, `requestSelection`, 400 ms, land, halo off after 1.2 s; landing haptic from `landingFeedbackUri`; `ListSelectedTitle` takes focus on arrival (merged semantics + focusRequester). `ui/lists/ListCoverHalo.kt` (2 dp at 5 dp + 14 % 8 dp at 11 dp, `foregroundTinted`) — starts visible and fades out over 1.2 s, as the iOS code does (the iOS doc says "fades in").
- `ListCoverFlow`: haptic only on a selection change between two non-null books (first selection on opening never ticks, on every list; a swipe now ticks at settle); programmatic moves take a 400 ms FastOutSlowIn tween (arrival, tap on a side cover, add); cover split outer Box / inner clip so the halo draws outside.
- `ui/common/ReducedMotion.kt`: `rememberReducesMotion()` (ANIMATOR_DURATION_SCALE == 0), also used by `CoverWall`. Reduced motion: no scroll, the halo still fades.
- `ListRow` optional `background`; `ListRowDivider` internal. String `book_in_lists` « Dans les listes ».
- Tests: `BookListEntryTest` (5), `ListArrivalFocusTest` (11). Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest --rerun` ✅ 624 tests, 0 failures.
- Runtime not run: no inventaire.io credentials for the agent. Timing, halo, haptic count, TalkBack focus, dark rendering unseen.

## Review

### Round validation — 2026-11-10

- Scope: from the stack point, `origin/wa/94-add-android-private-notes...wa/97-add-android-books-lists-section`; rebased onto #94's reviewed tip (`83722e6`) first.
- Findings, fixed, re-verified clean:
  - 🔴 [correctness] The branch still had #94's duplicate `mine-details:` key (Fiche livre of an owned book crashed): gone with the rebase onto #94's fix.
  - 🟠 [correctness] `inLists` was seeded by `onStart { emit(emptyList()) }`, so coming back after 5 s dropped « Dans les listes » for a frame and could shift the scroll: now `stateIn(viewModelScope, WhileSubscribed(5_000), emptyList())`, replaying the last rows. No unit test: `BookViewModel` has no test harness.
  - 🟡 [structure] `ListRowDivider` moved to `ui/lists/ListRow.kt`.
  - 🟡 [style] `book_in_lists` has its own comment in `strings_book.xml`.
- Final: `LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓` — clean; every `BookScreen` lazy key unique. Build ✅, 626 tests, 0 failures.
- ⚠️ Code changed since the user's test: coming back to a Fiche livre from a list.
- Wiki: nothing task-specific; the sprint's feature doc is written with #101.
- Screenshots: none — `verify.platform: ios`, this task is Android.
- ⛔ Lands after #94: PR stays draft on `wa/94-…` until #94 merges, then rebase onto the sprint branch and `gh pr edit --base`.

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
