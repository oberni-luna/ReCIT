---
issue: 173
status: to-test
wiki: [[features/0064-a-friends-profile-with-tabs]], [[features/0066-a-friends-profile-tabs-as-pages]], [[features/0067-a-friends-profile-presentation-tab]], [[features/0075-lens-tabs-and-a-lists-pager]]
note: Split from #172 (Fiche livre in tabs), which builds on it. Grilled 2026-11-22.
created: 2026-11-22
---

## Context / Decisions

> Split from #172: the friend's profile folding header machinery moved to Components/ so the Fiche livre can reuse it.

The Profil d'un ami folds its header as the page scrolls: picture and name shrink into the navigation bar, the tabs stay pinned under it, a scroll left halfway lands folded or unfolded, the fold is blended between pages while the pager moves. #172 gives the Fiche livre the same behaviour. Two copies of this scroll code would drift, so it is extracted first, alone, with no visible change.

1. **What moves.** The generic part of `Features/Community/`: `ProfileScrollOffset`, `ProfileHeaderCollapse`, `ProfileHeaderSnapBehavior`, and the page shell of `UserProfilePage` (first row as tall as the unfolded header, scroll reported per page, snap). They go to `Features/Components/` under neutral names (no `Profile` / `User`), next to `TabPager`, which is already generic.
2. **What stays in `Community/`.** Everything about a reader: picture, name, étagères, bio, the tabs' content, `UserProfileTab`, the header's own layout (`UserProfileStickyHeader` keeps drawing the picture and the name, fed the fold by the shared part).
3. **Shape.** One generic container taking the tabs, a header builder and a page builder, with the fold read off a shared position object (the role `ProfileScrollOffset` has today, so a scroll redraws the header only). Exact API left to `/wa-code`; it has to fit both the profile and the Fiche livre of #172 (cover + title + author line + three capsules).
4. **Tests.** `ProfileHeaderCollapse`'s existing tests move with it, renamed. No new behaviour, so no new test beyond what the rename needs.
5. **No change on screen.** Profil d'un ami, mine and a friend's, behaves exactly as before. iOS only: Android has its own implementation.

## Acceptance criteria

- A friend's profile opens with the picture, name and tabs (Inventaire • N, Listes • N, Échanges • N, Présentation) as before.
- Scrolling Inventaire folds the header into the navigation bar; the tabs stay pinned under it.
- Releasing a scroll halfway through the fold lands folded or unfolded, never in between.
- Swiping from a scrolled Inventaire to an unscrolled Listes unfolds the header as the page slides, and back.
- Holding a book on a friend's étagère still freezes the pager.
- Tapping the friend's photo still opens it full screen.
- My own profile (from my avatar) has no Échanges tab, as before.
- No type under `Features/Components/` names a profile or a user.
- Build passes with SwiftLint; the moved collapse tests pass.

## Implementation

- `Features/Components/` (new): `FoldingHeaderCollapse` (was `ProfileHeaderCollapse`), `FoldingHeaderScrollOffset<Tab>` (was `ProfileScrollOffset`), `FoldingHeaderSnapBehavior` (was `ProfileHeaderSnapBehavior`), `FoldingHeaderPageLayout`, `FoldingHeaderPage` (page shell from `UserProfilePage`), `FoldingHeaderPager` (container: scroll object, header measurement, overlay, `TabPager`, single-page path).
- API: `FoldingHeaderPager(selection:tabs:collapse:) { scrollOffset in header } page: { layout in FoldingHeaderPage(layout) { rows } underHeader: { … }.holdsReadableWidth(_:) }.frozen(_:)`.
- `Community/`: `UserDetailView` sits on the container; `UserProfilePage` thin wrapper (étagères in content, bio under header); `UserProfileStickyHeader` type names only. Old three files deleted.
- `Tests/ProfileHeaderCollapseTests.swift` → `FoldingHeaderCollapseTests.swift`, pages as `[Int]`, no Community dependency.
- Moved code made lint-clean (baseline keyed by path): `rest`/`folded` inner names, `.init(...)`, static before instance, strict headers. No baseline edit, no `swiftlint:disable`.
- Build ✅ (SwiftLint strict) · tests ✅ FoldingHeaderCollapseTests + UserProfileTabTests, 10 passed.

## Review

## Verification

Simulator iPhone 17, existing session, friend OlivierB:
- ✅ profile opens with photo, name, Inventaire • 160 | Listes • 2 | Échanges • 3 | Présentation
- ✅ scrolling Inventaire folds the header into the bar, tabs pinned under it
- ✅ swipe from scrolled Inventaire to Listes unfolds the header
- not run: halfway snap, étagère freeze, photo full screen, my own profile
- ✅ no `Profile`/`User` type under `Features/Components/FoldingHeader*`

## Feedback
