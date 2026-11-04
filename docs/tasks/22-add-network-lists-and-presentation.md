---
issue: 22
status: to-test
wiki: [[features/0068-lists-in-my-network]], [[features/0073-a-lists-presentation-tab]], [[features/0074-a-lists-visibility-in-its-form]], [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0062-android-catches-up-with-1-7-0]]
note: split from #20; sprint Android 1.3.0; builds on #21 (same branch)
created: 2026-11-04
---

## Context / Decisions

> « Dans mon réseau », a list's Présentation tab. Split from #20 on 2026-11-04.

- **Goal:** the Listes tab and a list's detail on Android match iOS 0068 and 0073, with 0075's pager but no lens.
- **Builds on #21:** creator model, scoped sync, read-only list, sliding capsule + pager. Coded after #21 on the same branch `sprint/android-1-3-0`.
- **Network lists sync (0068):**
  - `GET /api/lists/by-creators?users=a|b|…&with-elements=true`, 50 friends per request.
  - Runs at launch in `SessionCoordinator`, after my lists.
  - Only `.friend` relations count.
  - Pruning scoped to the creators asked; an answer without a creator is dropped.
- **Listes tab sections:** « Mes listes » by name, then « Dans mon réseau », friends' lists most recently changed first. Headers only when the network has lists.
- **Network row:** a meta line above the name — 16 pt avatar + « Léa • 14 œuvres »; explanation up to 3 lines; opens read-only; no swipe to delete.
- **Search** filters both sections; an emptied section disappears.
- **I have no list but friends do:** a tinted « Créer une liste » row heads the tab.
- **List detail tabs (0073):** « Livres • 8 » (or « Auteur·ices • 3 ») | « Présentation », pinned under the bar, simple sliding capsule.
- **Pager (0075 without lens):** Livres | Présentation side by side; a swipe outside the covers turns the page; the cover flow keeps its own swipe; the add bar slides with Livres; pager frozen while a comment is edited.
- **Présentation page:** description card with tappable links, Type, Visible par, Créée le, Modifiée le; empty → « Cette liste n'a pas de description »; add bar hidden. Friends' lists alike.
- **Visibility label:** `ListVisibility` decoded in words, groups included (« Mes groupes »).
- **Wording:** strings copied from iOS 0068 / 0073.

## Acceptance criteria

- [ ] Signed in with friends who own lists: Listes shows « Mes listes » then « Dans mon réseau », friends' lists newest change first
- [ ] Network row: 16 pt avatar + « Prénom • N œuvres » above the name; tap → read-only list; no swipe to delete
- [ ] No friend list at all → no section headers, my lists as before
- [ ] I own no list, friends do → tinted « Créer une liste » row on top
- [ ] Typing in search filters both sections; a section with no match disappears
- [ ] A list opens on « Livres • N » | « Présentation »; swipe outside the covers turns the page; swiping covers moves the cover flow
- [ ] Présentation: description with links, Type, Visible par in words, Créée le, Modifiée le; empty → « Cette liste n'a pas de description »; no add bar
- [ ] Editing a comment on Livres: page swipe disabled until done
- [ ] Unit tests: by-creators batching (50 per request), scoped pruning, section ordering, visibility label

## Implementation

- **Network sync:** `ListRepository.syncNetworkLists(friendIds)` — `by-creators` in batches of 50 (`data/lists/ListCreatorBatches.kt`), one after another, a failure stops the rest; prunes only the friends asked (`ListSyncPlan`). Run by `SessionCoordinator` right after my lists, outside the sync-status tracking (as iOS). Only `UserRelation.Friend`.
- **Friend filter:** in `ListsViewModel`, combining `observeAllLists()` with `observeByRelation(Friend)`, split by the pure `ListsTabSections` (as iOS), not a store query.
- **Listes tab:** « Mes listes » by name, « Dans mon réseau » newest change first; headers only when friends have lists; search filters both; tinted « Créer une liste » on top when I have none but friends do.
- **Row:** `ListRow` count line above the name; a friend's starts with a 16 dp avatar + name; description 3 lines in new `content200`; friends' rows read-only, no swipe.
- **List screen:** `ListDetailTab` « Livres • N » / « Auteur·ices • N » | « Présentation » with #21's `CapsuleTabs` + pager; add bar inside Livres; pager frozen while a comment is edited; empty work/author list → tabs + « Cette liste est vide ».
- **Présentation:** `ListPresentationPage` — selectable description with links (`ui/common/WebLinks.kt`), Type, Visible par (`ListVisibility` in words, groups included), Créée le, Modifiée le when changed; empty « Cette liste n'a pas de description ».
- **Design system:** `content200` (Alegreya Medium 15 sp) and `ThumbnailSize.XXSmall` (16 dp) added.
- **Not ported:** lens; tab group screen-reader label; avatar initials at 16 dp (grey disc); links on bare domains without `www.`; fade of the list under the tabs.
- **Unverified:** at the first/last cover, an extra swipe may turn the outer page.
- **Proof:** `./gradlew assembleDebug :app:testDebugUnitTest` green, 570 tests (13 new: `ListCreatorBatchesTest`, `ListsTabSectionsTest`, `WebLinksTest`, cases in `ListSyncPlanTest`, `ListVisibilityTest`). Never run on an emulator.

## Verification

manual validation — not run by agent
