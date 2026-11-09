---
issue: 95
status: todo
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
