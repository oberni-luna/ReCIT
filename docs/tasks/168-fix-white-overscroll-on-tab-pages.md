---
issue: 168
status: todo
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

## Review

## Verification

## Feedback
