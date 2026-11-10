---
issue: 95
status: to-close
wiki: [[features/0088-tab-bar-hidden-on-pushed-screens]], [[features/0089-tabbed-shelf-screen]], [[features/0031-android-app]]
note: Rattrapage iOS 1.10.0 (feature 0088, amended by 0089). MainScaffold always shows the NavigationBar.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0088](../wiki/features/0088-tab-bar-hidden-on-pushed-screens.md) as amended by [0089](../wiki/features/0089-tabbed-shelf-screen.md).

- **Which tabs.** Inventaire, Listes and Réseau hide the bar on every pushed screen, at any depth. Recherche keeps it on every screen. Same rule as iOS, per tab: a friend's profile reached from Recherche keeps the bar.
- **Rule lives in `MainScaffold`.** It alone holds the stacks: the bar shows when the selected tab is Recherche or `stacks.getValue(selected).size == 1`. `AppTab` carries whether it hides the bar on push (Search = false). Nothing inside a stack sets the bar's visibility.
- **Animation: slides down with a fade**, in step with `NavDisplay`'s push transition; slides back up on pop. `AnimatedVisibility` around the `NavigationBar`, `slideOutVertically` + `fadeOut` / `slideInVertically` + `fadeIn`. Content must not jump: the space the bar frees is taken by the pushed screen, no blank strip at the bottom.
- **Predictive back** (gesture): the bar comes back once the pop is committed, not with the finger — accepted, as iOS.
- **Re-tapping the selected tab** pops to root: the bar is then visible (depth 1).
- **My list's « Ajouter un livre »** (`ListAddBar`, today « above the tab bar, which Android keeps ») now sits at the bottom in the bar's place, insets included; its KDoc is updated. A friend's list loses the bar too.
- The profile overlay and the sort flow are untouched: they already cover the bar.

## Acceptance criteria

- Réseau → a friend's profile: the bar slides down and fades as the profile slides in; back: it slides back up.
- Réseau → a group → its members: no bar at either depth; back to root: the bar is back.
- Listes → my list: no bar, « Ajouter un livre » at the bottom of the screen, above the system navigation bar, nothing hidden behind it.
- Listes → « Dans mon réseau » → a friend's list: no bar.
- Inventaire → an étagère, and Inventaire → a book: no bar.
- Recherche → a book, and Recherche → a friend's profile: the bar stays.
- With a pushed screen in Réseau, tapping the Réseau tab again pops to root and the bar shows.
- Switching from Réseau (pushed screen, no bar) to Recherche shows the bar; back to Réseau hides it again.
- Profile overlay and « Ranger mes livres » open and close as before.

## Implementation

- `ui/navigation/AppTab.kt`: `hidesTabBarOnPush` (Search = false) and the pure rule `showsTabBar(isAtRoot) = isAtRoot || !hidesTabBarOnPush`.
- `ui/root/MainScaffold.kt`: Shell reads `selected.showsTabBar(isAtRoot = stacks.getValue(selected).size == 1)`; the `NavigationBar` moved to a private `TabBar` in `AnimatedVisibility` (`slideIn/OutVertically { it }` + fade, `tween(700)`, NavDisplay's default crossfade). A `NavEntryDecorator` (`tabBarRoomDecorator`) pads and consumes the bar's height only on entries the bar shows over (the root, every Recherche entry): a pushed screen gets the full height from its first frame, the bar slides away over it, no jump, no blank strip. Root identified by `entries(tab.root).contentKey`. Scaffold `contentWindowInsets` → `WindowInsets.navigationBars.only(Bottom)` so the SnackBar stays above the system bar.
- `ui/lists/ListAddBar.kt`: KDoc only — in the tab bar's place, above the system bar; above the tab bar from Recherche.
- `ui/lists/EntityListScreen.kt`: `.consumeWindowInsets(padding)` on the content Box, so the comment field's `imePadding` does not count the system bar twice.
- `ui/book/BookScreen.kt`: last list item `Spacer(windowInsetsBottomHeight(navigationBars))` — the only pushed screen with `contentWindowInsets = WindowInsets(0)`; adds nothing in Recherche where the insets are consumed.
- Tests: `ui/navigation/AppTabTest.kt` (3: every tab shows the bar at root; Inventaire, Listes, Réseau hide it pushed; Recherche keeps it).
- Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest` ✅ 603 tests, 0 failures.
- Other pushed screens (User, Shelf, Group, GroupMembers, Author, Work, AddFriends, Invitations, FindGroups, InviteToGroup, EntityList, EditEdition) use default Scaffold insets: they now get the system-bar inset themselves, as they already do inside ProfileSheet and the sort flow.
- Known, left alone: `EditEditionScreen` / `FormPageScaffold` add `imePadding` to unconsumed Scaffold padding; with the keyboard up in Inventaire the gap may be one system-bar height too tall (already so in the sort flow).
- Predictive back: the bar returns once the pop is committed (accepted by the task).
- Runtime not run: no inventaire.io credentials for the agent.

## Review

### Round validation — 2026-11-10

- Scope: `origin/sprint/android-1-4-0...wa/95-hide-android-tab-bar-on-push`.
- Finding (🟡 minor), fixed by autofix, re-verified clean:
  - [correctness] With the tab bar gone, nothing above pushed forms consumed the bottom inset, so `imePadding()` counted it twice and a strip opened above the keyboard. `.consumeWindowInsets(padding)` after `.padding(padding)` in `EditEditionScreen` and `FormPageScaffold`.
- Final: `LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓` — clean. Build ✅, 603 tests, 0 failures.
- ⚠️ Code changed since the user's test: edition and property forms with the keyboard up.
- Wiki: nothing task-specific; the sprint's feature doc is written with #101.
- Screenshots: none — `verify.platform: ios`, this task is Android.

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
