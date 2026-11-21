---
issue: 168
status: to-test
wiki: [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0089-tabbed-shelf-screen]], [[features/0066-a-friends-profile-tabs-as-pages]]
note: Quand on swipe au-delà des pages, dans les écrans avec des tabs (Liste ou Étagère), on voit du blanc en background. Ce n'est pas le cas dans l'écran de profil. Aligner sur l'écran de profil.
created: 2026-11-21
---

## Context / Decisions

> Quand on swipe au-delà des pages, dans les écrans avec des tabs (Liste ou Étagère), on voit du blanc en background. Ce n'est pas le cas dans l'écran de profil. Tu peux aligner sur l'écran de profil pour le background des pages dans les List et les Etagères ?

- Swiping past the first or last page of a Liste or an Étagère shows white in the gap the pager's bounce opens.
- A friend's profile shows grey there: `UserDetailView` lays `DesignSystem.Color.backgroundForm` behind its `TabPager`, `ignoresSafeArea()`.
- `ListCoverFlowScreen` and `ShelfDetailView` lay nothing behind theirs. `TabPager` and its hosting controllers are `.clear`, so the gap shows the window's white.
- Each page is already a `DesignSystem.FormList` on `backgroundForm`: only the gap is wrong.
- Fix on each screen, as the profile does: the same `.background { backgroundForm.ignoresSafeArea() }` behind the `TabPager` of `ListCoverFlowScreen` and `ShelfDetailView`.
- `TabPager` itself stays untouched, the profile too.
- Dark mode follows from the token, nothing to add.

## Acceptance criteria

- On a Liste, swiping right on « Livres » or left on « Présentation » past the end → the gap shows the pages' grey, not white.
- On an Étagère (mine or a friend's), same swipe past either end → same grey, no white.
- Same two checks in dark mode → the gap matches the pages' dark ground.
- A friend's profile → unchanged.

## Implementation

- `ListCoverFlowScreen` and `ShelfDetailView`: `.background { DesignSystem.Color.backgroundForm.color.ignoresSafeArea() }` on the inner `ZStack(alignment: .top)` holding the `TabPager` and the tab picker, as `UserDetailView` does. One comment line each says why.
- `TabPager`, `UserDetailView`, the SwiftLint baseline: untouched.
- Build: `** BUILD SUCCEEDED **`, scheme `ReCIT_iOS`, iPhone 17 simulator, SwiftLint in the build. `swiftlint --fix` changed nothing.
- No unit test: visual change only.

## Review

## Verification

manual validation — not run by agent

## Feedback
