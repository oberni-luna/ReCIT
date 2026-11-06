# The tab bar leaves with the push, in Réseau and Listes

Shipped on 2026-11-06, iOS only (issue #50). In Réseau, a group or a friend's profile opened over the tab bar. In
Listes, only my lists hid it, so « Ajouter un livre » could take its place ([0060](0060-list-cover-flow.md)), and the
bar vanished at once instead of moving with the push. Now every screen pushed in these two tabs hides the tab bar, and
it fades out and back in with the push and the pop.

## What it does

- In Réseau and Listes, the tab's root shows the tab bar. Every screen pushed onto it hides the bar, at any depth: a
  friend's profile, a group and its members, « Ajouter des ami·es », a book or an Échange opened from a profile, a
  list (mine or a friend's), a book opened from a list. This is what UIKit's `hidesBottomBarWhenPushed` does.
- The bar fades out while the pushed screen slides in, and fades back in while the root slides back. No jump, no gap
  at the bottom.
- An interactive swipe-back keeps the bar hidden during the swipe; it fades in once the swipe completes. A cancelled
  swipe changes nothing.
- My lists keep « Ajouter un livre » at the bottom, in the bar's place. A friend's list, which kept the tab bar until
  now, hides it too.
- Inventaire and Recherche are unchanged: they keep the tab bar on every screen. The rule is per tab, so a friend's
  profile reached from Recherche keeps it, and a list opened from the Fiche livre's « Dans les listes »
  ([0079](0079-the-lists-a-book-is-in.md)) in Inventaire or Recherche keeps it too. On my list there, « Ajouter un
  livre » sits above the tab bar.

## Technical surface

- `DesignSystem/Extensions/View+hidesTabBarWhenPushed.swift`: `hidesTabBarWhenPushed(on: NavigationPath)`, applied to
  a tab's `NavigationStack`. A private `TabBarHiddenWhenPushed` modifier sets
  `toolbarVisibility(.hidden / .visible, for: .tabBar)` from a `@State` flag, which `onChange(of: !path.isEmpty,
  initial: true)` flips inside `withAnimation`. The bar follows the stack's path, so it reacts only when a push or a
  pop is committed.
- `NetworkView` and `EntityListView` apply it once, on their `NavigationStack`. Nothing inside the two stacks sets
  the tab bar's visibility.
- `ListCoverFlowScreen` loses its own `.toolbar(isMine ? .hidden : .automatic, for: .tabBar)`. « Ajouter un livre »
  keeps its place through `formActionBar`.

### Three routes tried

Judged on video frames of the simulator (iPhone 17, iOS 26.4). The task asked for framework APIs only, SwiftUI first.

1. `toolbarVisibility(.hidden, for: .tabBar)` on each pushed destination: the bar disappeared before the push slid
   in, and came back about 300 ms after the pop ended. Rejected.
2. UIKit's `hidesBottomBarWhenPushed` on the pushed hosting controller: no effect under SwiftUI's `TabView`, the bar
   stayed on the pushed screen. Rejected and removed.
3. Kept: the visibility set on the stack itself, driven by its path, animated with `withAnimation`. The bar fades
   with the transition.

## Not done / owed

- On an interactive swipe-back, the bar fades in after the swipe ends, not with the finger. Accepted by the task's
  criteria.
- Seen by the agent on the simulator (iPhone 17, iOS 26.4): Réseau → a friend's profile and back, the bar fading with
  the transition; Listes → « Dans mon réseau » → a friend's list, without the bar.
- Not checked: a group and its members, « Ajouter des ami·es », a book from a profile, my list with « Ajouter un
  livre », a swipe-back cancelled half-way, switching tabs with a detail open, a list opened from the Fiche livre,
  iOS 18. e2e was not run.
