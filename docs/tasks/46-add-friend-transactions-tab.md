---
issue: 46
status: to-test
wiki: [[features/0064-a-friends-profile-with-tabs]], [[features/0066-a-friends-profile-tabs-as-pages]], [[features/0067-a-friends-profile-presentation-tab]], [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0071-a-request-names-what-it-asks-for]]
note: un tab sur l'écran des ami·es pour afficher les transactions effectuées ou en cours avec cet·te ami·e
created: 2026-11-06
---

## Context / Decisions

> Je veux ajouter un tab à l'écran des users amis pour afficher les transactions effectuées ou en cours avec cet·te ami·e.

- **What**: the Profil d'un ami (`UserDetailView`) gains a fourth tab, « Échanges • N », listing every Échange (`UserTransaction`) between me and that friend.
- **Design**: Figma « Détail d'un amis » (`865:17783`, page `Réseau`), frames `F7 · Profil ami · Échanges, en cours et terminés` (`967:5361`) and `F8 · Profil ami · Échanges · Aucun échange` (`967:5583`), component `Profile / Tabs` (`875:5287`, variant `Selected=Échanges`), spec panel `Spec · Détail d’un ami`.
- **Word**: « Échanges » / « Transactions », the glossary's `Échange`. « Prêts » considered and dropped: the tab also holds sales and gifts.
- **Tab order**: Inventaire • N | Listes • N | Échanges • N | Présentation. `UserProfileTab` gains a case between `.lists` and `.presentation`; the pager gets a fourth page.
- **Count**: every transaction with the friend, both directions (they own the copy or I do), any state.
- **Unread dot**: a `foregroundTinted` dot after the label while one of those transactions is unread on my side (same rule as `TransactionCellView.isRead`).
- **Content**: two sections, as on « Toutes les transactions » (`AllTransactionsView`):
  - « En cours » (`isCurrent`: requested, accepted, confirmed), then « Terminés » (returned, declined, cancelled).
  - Each sorted by `lastActionDate`, newest first. An empty section is not shown.
  - Rows are `TransactionCellView` **unchanged**, its sentence included (« Vous souhaitez l'emprunter à Camille »), even though it repeats the name and stays in the present tense for a finished one. Decided: one cell for the whole app.
  - A row pushes the Échange screen (`NavigationDestination.transaction`) on the profile's path.
- **Empty tab is shown**, never hidden: « Échanges • 0 », then a secondary `EmptyStateView`, no action, glyph `arrow.left.arrow.right`, title « Aucun échange avec <name> », body « Quand l’un·e de vous demandera un livre à l’autre — pour l’emprunter, l’acheter ou le récupérer —, l’échange apparaîtra ici. » English in the same spirit.
- **Tab row scrolls**: four labels fit a phone (≈ 355 pt at 540 books, capsules at `spacing/small` horizontal padding instead of `s-medium`). When they do not fit (large Dynamic Type), the row scrolls horizontally instead of overflowing; the selected tab is scrolled into view, also when a swipe changes the page. Fits → laid out as today. The lens (feature 0075) keeps working.
- **Data**: local only. `TransactionModel.syncTransactions` already stores all my transactions; filter `UserTransaction` on `owner._id` or `requester._id` == the friend's `_id`. No new endpoint.
- **Where it shows**: a friend's profile only (`showsInventory` and not me). My own profile and non-friends: no Échanges tab (non-friends already have no tabs).
- **New file**: `Features/Community/UserTransactionsTab.swift`, next to `UserListsTab` / `UserPresentationTab`.
- **iOS only.** Android follows in its own task, blocked by this one.

## Acceptance criteria

- [ ] Friend with 2 ongoing + 3 finished transactions → tab row reads « Inventaire • N · Listes • N · Échanges • 5 · Présentation ».
- [ ] Tap « Échanges » → section « En cours » with the 2 ongoing, then « Terminés » with the 3 finished, each newest last action first.
- [ ] Transactions where the friend asks for my copy and where I ask for theirs both appear.
- [ ] Transactions with other readers never appear.
- [ ] Only finished transactions → « En cours » section absent; only ongoing → « Terminés » absent.
- [ ] Tap a row → Échange screen of that transaction; back → Échanges tab, still selected.
- [ ] An unread transaction with that friend → tinted dot after « Échanges • N »; once read, no dot.
- [ ] Friend with no transaction → « Échanges • 0 », empty state « Aucun échange avec <name> », no button.
- [ ] Swipe from Listes → Échanges page; swipe again → Présentation.
- [ ] Largest accessibility text size → tab row scrolls sideways, nothing clipped; selecting Présentation by swipe brings its capsule into view.
- [ ] Default text size on iPhone 17 → four tabs fit, no scrolling.
- [ ] My own profile → no Échanges tab.
- [ ] Light and dark: cells and empty state on the same backgrounds as Listes.

## Implementation

- `UserProfileTab` gains `.transactions` between `.lists` and `.presentation`; `UserProfileTab.pages(isMine:)` → four tabs on a friend's profile, three on mine; non-friends keep one page, no tabs.
- `TabPager`, `LensTabPicker`, `LensTabLabels` take `tabs: [Tab]` (default `allCases`, so a list's Livres | Présentation is unchanged); `TabPager` rebuilds its pages when the list changes.
- `ProfileScrollOffset` takes the page list (`among:`): Présentation is index 3 on a friend's profile, 2 on mine. `ProfileHeaderCollapseTests.clampedPosition()` updated (3 lines) to the new signature.
- New `Features/Community/UserTransactionsTab.swift`, `UserTransactionsSection.swift`, `UserTransactionsTabTitle.swift` (« Échanges • N » + tinted unread dot); `Model/Transaction/TransactionsWithUser.swift` (owner or requester == the friend, newest `lastActionDate` first, split on `isCurrent`, from a plain `@Query`); rows are `TransactionCellView`, ids `e2e.user.transactionRow`.
- `TransactionCellView.isRead` moved to `UserTransaction.isRead(by:)` (`Model/Transaction/UserTransaction+ReadStatus.swift`), used by the cell and the tab dot. Behaviour unchanged. **To check:** the rule reads "read" when my server `read` flag is `false`, while the app creates its requests with `requester: true` — the dots may show on read transactions. Kept as is, per the task.
- Tab row: `ViewThatFits` — fits → laid out as before with the lens; overflows → horizontal `ScrollView` + `ScrollViewReader` bringing the selected word into view on tap and swipe. While it scrolls, a word is picked by a tap; the capsule cannot be dragged (the lens drag would block scrolling). The capsule still follows the pager.
- Profile capsules padded `.small` through `.wordPadding(.small)`; a list keeps `.sMedium`.
- Strings, fr + en: `user.tab.transactions`, `user.tab.transactions %lld`, `user.tab.transactions.accessibility %lld`, `user.tab.transactions.unread`, `user.transactions.current` « En cours », `user.transactions.finished` « Terminés », `user.transactions.empty.title %@`, `user.transactions.empty.message`. Existing « Transactions en cours / finies » headers not reused (glossary: Échange).
- Members reordered in `TabPager` and `LensTabPicker` for SwiftLint; their baseline entries are now stale (baseline not grown).
- Proof: build ✅ · tests ✅ — `TransactionsWithUserTests` 5, `UserProfileTabTests` 2, `LensTabTrackTests` 8, `ProfileHeaderCollapseTests` 8, `TransactionModelTests`.

## Review

## Verification

manual validation — not run by agent. Owed: every acceptance criterion on screen — counts, sections, both directions, row → Échange and back, dot, empty state, swipes, header fold on four pages, largest text size scrolling, my own profile with three tabs, light/dark, a list's Livres | Présentation unchanged.

## Feedback
