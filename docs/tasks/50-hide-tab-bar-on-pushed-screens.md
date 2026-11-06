---
issue: 50
status: to-close
wiki: [[network]], [[lists]], [[platform-and-design]], [[features/0060-list-cover-flow]], [[features/0028-network-tab-and-groups]], [[features/0068-lists-in-my-network]]
note: "quand on navigue depuis l'écran « Réseau » vers le détail d'un groupe ou d'un user, il faut faire disparaître la tabbar en bas. C'est déjà le cas pour les Listes, mais c'est pas fluide. Peux tu faire disparaître la tabbar pour l'écran des listes et pour l'écran réseau, mais que ce soit fluide et animé (en utilisant des features framework serait mieux)"
created: 2026-11-06
---

## Context / Decisions

> quand on navigue depuis l'écran « Réseau » vers le détail d'un groupe ou d'un user, il faut faire
> disparaître la tabbar en bas. C'est déjà le cas pour les Listes, mais c'est pas fluide.
>
> Peux tu faire disparaître la tabbar pour l'écran des listes et pour l'écran réseau, mais que ce
> soit fluide et animé (en utilisant des features framework serait mieux)

- **Today:**
  - Only `ListCoverFlowScreen` hides the tab bar: `.toolbar(isMine ? .hidden : .automatic, for: .tabBar)`. Only my lists hide it, because « Ajouter un livre » takes its place (feature 0060). A friend's list keeps it.
  - The bar vanishes abruptly instead of moving with the push.
  - Réseau (`NetworkView`) hides nothing.
- **Rule:** in the Réseau and Listes stacks, the tab's root keeps the tab bar, and **every pushed screen** hides it, at any depth. Examples: a group, a friend's profile, « Ajouter des ami·es », a group's members, a book or an Échange opened from a profile, a list (mine or a friend's), a book opened from a list. This is the same semantics as UIKit's `hidesBottomBarWhenPushed`.
  - Popping back to the root brings the tab bar back.
- **Smooth:** the tab bar leaves and comes back with the push and pop animation, interactive swipe-back included. No jump, no flash, no gap left where the bar was. Checked on iOS 18 and iOS 26.
- **Where:** the rule is applied once per stack, in `NetworkView`'s and `EntityListView`'s `navigationDestination`, never screen by screen. `ListCoverFlowScreen`'s own `isMine` modifier goes. « Ajouter un livre » stays on my lists, in the bar's place.
- **Mechanism:** framework APIs only.
  1. SwiftUI first: `toolbarVisibility(.hidden, for: .tabBar)` (or `.toolbar(.hidden, for: .tabBar)`).
  2. If that jumps or flashes on iOS 18 or 26, fall back to UIKit's `hidesBottomBarWhenPushed` on the pushed hosting controllers. The fallback is isolated in one file under `DesignSystem/`, exposed as one SwiftUI modifier.
  - No third-party introspection package.
  - The implementer records in `## Implementation` which route was taken, and why.
- **Out of scope:** the Inventaire and Recherche stacks keep the tab bar on every screen. A friend's profile reached from Recherche keeps it too, since the rule is per stack. Android is untouched.
- **Type:** `improvement` (the Listes behaviour changes; Réseau gains it).

## Acceptance criteria

- [ ] Réseau → tap a friend → the friend's profile slides in and the tab bar slides away with it; back → the tab bar slides back.
- [ ] Réseau → Groupes → tap a group → same; the group's members, pushed from it, also have no tab bar.
- [ ] Réseau → « Ajouter des ami·es » → no tab bar.
- [ ] Friend's profile → tap a book → Fiche livre without a tab bar; back twice → Réseau with its tab bar.
- [ ] Listes → tap one of my lists → no tab bar, « Ajouter un livre » at the bottom; back → tab bar back.
- [ ] Listes → « Dans mon réseau » → tap a friend's list → no tab bar (it had one before).
- [ ] Interactive swipe-back, half-way then cancelled → the tab bar does not flash or stay half-shown; completed → it is back.
- [ ] No jump, flash or empty gap at the bottom during push or pop, on iOS 26 and iOS 18.
- [ ] Inventaire → Fiche livre and Recherche → any result keep the tab bar, as today.
- [ ] Root screens of Réseau and Listes always show the tab bar, also after switching tabs while a detail is open and coming back.

## Implementation

- **Route taken: SwiftUI, driven by the stack's path.** Three routes tried, judged on video frames (simulator, iPhone 17, iOS 26.4):
  1. `toolbarVisibility(.hidden, for: .tabBar)` on each pushed destination: the bar vanished before the push slid in, and popped back ~300 ms after the pop ended. Rejected.
  2. UIKit `hidesBottomBarWhenPushed` on the pushed hosting controller: no effect under SwiftUI's `TabView`, the bar stayed on the pushed screen. Rejected and removed.
  3. Kept: `toolbarVisibility(isTabBarHidden ? .hidden : .visible, for: .tabBar)` on the `NavigationStack` itself, with `isTabBarHidden` set inside `withAnimation` from `onChange(of: !path.isEmpty, initial: true)`. The bar fades out during the push and back in during the pop.
- New `ReCIT_iOS/DesignSystem/Extensions/View+hidesTabBarWhenPushed.swift`: `hidesTabBarWhenPushed(on: NavigationPath)` + private `TabBarHiddenWhenPushed` modifier.
- `NetworkView`, `EntityListView`: `.hidesTabBarWhenPushed(on: path)` on their `NavigationStack`. Nothing inside the two stacks sets tab bar visibility.
- `ListCoverFlowScreen`: `.toolbar(isMine ? .hidden : .automatic, for: .tabBar)` removed; « Ajouter un livre » keeps its place through `formActionBar`.
- **Side effect, follows the decision:** a list opened from the Fiche livre's « Dans les listes » in Inventaire or Recherche keeps the tab bar; on my list there, « Ajouter un livre » sits above it.
- Interactive swipe-back: the path changes only when the swipe completes, so the bar stays hidden during the swipe and fades in after; a cancelled swipe changes nothing.
- Proof: build ✅ (SwiftLint in the build).

## Review

### Round `validation` — 2026-11-06

Scope: `origin/main..wa/50-hide-tab-bar-on-pushed-screens` (code). LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓.

- 🟡 `View+hidesTabBarWhenPushed.swift:7` — [style] rationale in the file header (style.md: nothing after « Created by ») → **fixed**: header back to the Xcode default, one line of why in the `///` of `hidesTabBarWhenPushed(on:)`, plus `- Parameter path:`. Comments only.
- Round 2: ✅ review clean.
- Noted, accepted by the criteria: on an interactive swipe-back the bar fades in after the swipe ends, not with it.

## Verification

PM on the simulator (iPhone 17, iOS 26.4, video frames every 50–60 ms):
- ✅ Réseau → friend's profile: the tab bar fades out while the profile slides in; no jump, no gap.
- ✅ Back: the tab bar fades in while Réseau slides back.
- ✅ Listes → « Dans mon réseau » → a friend's list: no tab bar.

Still yours: a group and its members; « Ajouter des ami·es »; a book from a profile; my list with « Ajouter un livre »; swipe-back half-way then cancelled; switching tabs with a detail open; iOS 18.

## Feedback
