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
- **Widened at feedback round 2: the Liste's and the étagère's tabs sit in the navigation bar on iOS 18**, as on a friend's profile. Before, the navigation bar kept its own material and hairline, and a second `.bar` lay under the capsules: a line cut the two apart. Now one material from the top of the screen to the tabs' foot, ending on a hairline. iOS 26+ unchanged (no backdrop, soft scroll edge).
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
- iOS 18: on a Liste and an étagère, no line between the navigation bar and the tabs; one material from the top of the screen to under the capsules, a hairline under them — as on a friend's profile.
- iOS 26+: a Liste's and an étagère's tabs unchanged — no backdrop, the page fading under the soft scroll edge.

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

### Feedback round 2 — the Liste's and the étagère's tabs in the navigation bar on iOS 18

- `Features/Lists/ListDetailTabPicker.swift` — `listDetailTabsBar()` below iOS 26: a `Divider` at the foot of its `.bar` backdrop, and `.toolbarBackgroundVisibility(.hidden, for: .navigationBar)`, so the navigation bar draws no material or hairline of its own over the tabs' backdrop — what `UserDetailView` does with `UserProfileStickyHeader`. The modifier is the Liste's (`ListCoverFlowScreen`) and the étagère's (`ShelfDetailView`), its only two callers. iOS 26 branch untouched.
- Backdrop always shown, not only once the page passes under it as on the profile: the Liste's and the étagère's tabs had it always.
- Build: iPhone 17 (iOS 26) and iPhone 16 Pro (iOS 18.6) `BUILD SUCCEEDED`, lint clean. `LensTabTrackTests` pass. Real screens not seen running (signed-in account needed).

## Review

## Verification

manual validation — not run by agent

round 1: manual validation — not run by agent

round 2: manual validation — not run by agent

## Feedback

### Round 1 — 2026-11-08

- Asked: « Pourquoi le titre de l'oeuvre est en majuscule ici alors qu'il est ok à l'écran précédent ? Même chose dans l'écran pour créer une transaction, il y a du allcaps, pourquoi ? Tu peux corriger ? »
- Cause: iOS 18 uppercases Section header content in List / Form; iOS 26 does not.
- Triage: adjustment — not in #89's scope; user chose to widen #89 (renamed « Fix iOS 18 visuals ») over a new task, and to cover every header, one line per List.
- Changes: see `## Implementation` → Feedback round 1. Implementer, no inline hunks.
- Review: deferred → /wa-validate. Verify: manual, not run by agent. No rule captured.

### Round 2 — 2026-11-09

- Asked: « L'écran de profil est propre sur iOS 18, alors que les écrans de détail d'une liste ou d'une étagère sont moches. il y a une bar entre la navigation bar et les capsules (cf screenshots). Tu peux corriger pour avoir toujours le même rendu que dans l'écran de profil : capsule stackées en haut comme si elles étaient dans la navigation bar. Attention à ne pas faire de regression sur iOS 26+. »
- Cause: below iOS 26 the navigation bar kept its own material and hairline, and `listDetailTabsBar()` laid a second `.bar` under the capsules; the profile hides the navigation bar's background and draws one backdrop down to the tabs' foot.
- Triage: adjustment — the iOS 18 criteria covered the capsule, not the bar behind it; two criteria added.
- Changes: see `## Implementation` → Feedback round 2. `inline`: `ListDetailTabPicker.swift`, `listDetailTabsBar()` (+4 lines).
- Review: deferred → /wa-validate. Verify: manual, not run by agent. No rule captured.
