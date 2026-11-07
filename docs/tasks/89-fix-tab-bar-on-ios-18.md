---
issue: 89
status: to-test
wiki: [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0086-a-friends-transactions-tab]], [[features/0045-running-on-ios-18]]
note: "sur iOS 18, notre tab bar ne marche pas bien. Il faut enlever le \"liquid glass\" et les effets de zoom sur iOS 18." Screen recording on an iPhone 16 Pro (iOS 18), 2026-11-07, kept locally (~/Desktop/Screen Recording iPhone 16 Pro 07-11-2026 at 17.26.57.mp4).
created: 2026-11-07
---

## Context / Decisions

> sur iOS 18, notre tab bar ne marche pas bien. Il faut enlever le "liquid glass" et les effets de zoom sur iOS 18.

- **"Tab bar" = the row of tabs at the top**, `LensTabPicker` (`Features/Components/LensTabPicker.swift`), not the system `TabView`. Seen in the recording on a friend's profile (Inventaire • 2 | Listes • 2 | Échanges • 0 | Présentation). The same component draws a Liste's (`ListDetailTabPicker`) and an étagère's (`ShelfDetailTabPicker`) tabs: the fix covers all three.
- **What the recording shows on iOS 18:**
  - the lifted capsule's magnified word is drawn off the capsule: « Lists • 2 » rises above it, cut in half;
  - the `.regularMaterial` capsule, `glassCapsule()`'s fallback, is barely visible on the dark profile ground (`gray/800`);
  - the ×1.2 magnification doubles letters while the capsule moves between two words.
- **iOS 26+ unchanged.** Glass, lift and magnification stay as they are. Everything below is behind `#available(iOS 26.0, *)` failing.
- **No zoom below iOS 26.** The capsule is not lifted (`liftScale` 1) and the words under it are not magnified (`magnification` 1).
- **The drag stays.** The capsule is still picked up, follows the finger, rubber-bands and settles; only the zoom goes. Tap, haptic ticks and following the pager are unchanged.
- **Capsule fill below iOS 26 = `backgroundDisable`** (white at 10 % in dark, `gray/200` in light), instead of `.regularMaterial`. A veil, so it reads on the profile's, the Liste's and the étagère's grounds alike. `glassCapsule()` (`DesignSystem/Extensions/View+glass.swift`) has no other caller: its fallback changes there.
- **Widened at feedback round 1: uppercase section headers on iOS 18.** iOS 18 uppercases whatever sits in a `List` / `Form` `Section` header; iOS 26 no longer does. Seen on the Fiche livre (the title in `EntityHeaderView`, « L'ÉTRANGER », while the screen before shows « L'étranger ») and on the request sheet (`TransactionFormView`, « BORROW 1984 FROM EXLIBRIS_IOS_70 »).
- **Every header, not only those two:** no section header is uppercased on iOS 18 — the iOS 26 look, plain titles such as « In my inventory » included. Set once (`.textCase(nil)`) where it reaches every list and form, not header by header.
- Out of scope: the system tab bar, the two-colour word while the capsule sits between two words (intended, as on iOS 26).

## Acceptance criteria

- iOS 18 simulator, friend's profile, dark: the selected tab's capsule is visible, a light grey capsule behind the word.
- iOS 18, light: the capsule is visible, `gray/200` behind the word.
- iOS 18: pressing and dragging the capsule moves it under the finger with no growth of the capsule and no enlarged words; released, it settles on a word and the page turns.
- iOS 18: at no point is the selected word drawn outside the capsule or cut (the « Lists • 2 » lifted above the capsule in the recording).
- iOS 18: same on a Liste's Livres | Présentation and an étagère's tabs.
- iOS 26+: glass capsule, lift ×1.15 and magnification ×1.2 exactly as before.
- iOS 18: the Fiche livre's title reads as typed (« L'étranger »), not in capitals.
- iOS 18: the request sheet's title and sentence read as typed (« Borrow 1984 from exlibris_ios_70 »).
- iOS 18: no section header in capitals anywhere — « In my inventory », the Profil's, Réseau's, Recherche's, forms' and sheets' sections included.
- iOS 26+: section headers unchanged.

## Implementation

- `DesignSystem/Extensions/View+glass.swift` — `glassCapsule()` below iOS 26: `background(DesignSystem.Color.backgroundDisable.color, in: .capsule)` instead of `.regularMaterial`. iOS 26 branch unchanged. Doc comment says what iOS 18 gets.
- `Features/Components/LensTabPicker.swift` — `liftScale` / `magnification` stay static computed vars in place: 1.15 / 1.2 under `#available(iOS 26.0, *)`, 1 otherwise. Header gains a paragraph on iOS 18: picked up, follows the finger, rubber-bands, settles, nothing grows.
- No statics moved: the frozen `type_contents_order` baseline entries still match. Baseline untouched, no `swiftlint:disable`.
- Build: iPhone 17 (iOS 26) and iPhone 16 Pro (iOS 18.6, built for that destination) `BUILD SUCCEEDED`, lint clean. `LensTabTrackTests` 8/8 pass.
- Not seen running: reaching a friend's profile needs a signed-in account. The cut word is drawn by the ×1.2-scaled overlay copy clipped by the ×1.15 capsule; both are 1 below iOS 26, so it should be gone — to check on device.


### Feedback round 1 — uppercase section headers on iOS 18

- `.textCase(nil)` only acts inside a List / Form on iOS 18 (on the Section, or a Group / view in the List's content); on the List itself or any ancestor it does nothing — probed on the iOS 18.6 simulator. So set per list, not once at the root.
- `DesignSystem.Form` and `DesignSystem.FormList`: `.textCase(nil)` on their content — covers every form and form list (request sheet included).
- Plain `List`s with section headers: `.textCase(nil)` on their content — on the existing `Group`, a new `Group`, or the top-level child where a `Group` would re-indent baseline-frozen lines: BookDetailView, BookResolvingView, InvitationsView, ReaderSearchView, UserProfilePage, WorkEditionPicker, ListAddSearchView, FindGroupsView, GroupDetailView, GroupMembersView, InviteToGroupView, AllTransactionsView, TransactionDetailView, AuthorDetailView, EditionDuplicatePairForm, ListsTabList, NetworkView.
- Recherche: `SearchContent.swift` is pinned by `file_length`, so the modifier sits in its five section views (Recents, Local, Friends, Suggestions, Remote).
- Profil: `connectedView(user:)` pinned at 103 lines — split into `ProfileSettingsSection`, `ProfileTransactionsSection`, `ProfileAboutInventaireSection`, `ProfileDeleteAccountSection` (new files), its six `e2e.profile.*` literals turned into `AccessibilityID` constants (values unchanged), then a `Group` with `.textCase(nil)`. `connectedView` now 50 lines, at the warning limit. Baseline: 8 entries removed, none added.
- Skipped: Lists with no section header (EntityListDetail's empty state, SearchAllLocalView, FriendsLatestBooksView, SortShelfDetailView — footer only), `#Preview`s.
- Build: iPhone 17 (iOS 26) and iPhone 16 Pro (iOS 18.6) `BUILD SUCCEEDED`, lint clean. `LensTabTrackTests` 8/8. Real screens not seen running (signed-in account needed).

## Review

## Verification

manual validation — not run by agent

round 1: manual validation — not run by agent

## Feedback

### Round 1 — 2026-11-08

- Asked: « Pourquoi le titre de l'oeuvre est en majuscule ici alors qu'il est ok à l'écran précédent ? Même chose dans l'écran pour créer une transaction, il y a du allcaps, pourquoi ? Tu peux corriger ? »
- Cause: iOS 18 uppercases Section header content in List / Form; iOS 26 does not.
- Triage: adjustment — not in #89's scope; user chose to widen #89 (renamed « Fix iOS 18 visuals ») over a new task, and to cover every header, one line per List.
- Changes: see `## Implementation` → Feedback round 1. Implementer, no inline hunks.
- Review: deferred → /wa-validate. Verify: manual, not run by agent. No rule captured.
