# A friend's profile: an Échanges tab

Shipped on 2026-11-06, iOS only (issue #46). The Profil d'un ami had Inventaire, Listes and Présentation
([0067](0067-a-friends-profile-presentation-tab.md)). The Échanges with that friend were only in « Toutes les
transactions », mixed with everyone else's. Now a friend's profile has a fourth tab, « Échanges • N », with every
Échange between me and them. Figma: section « Détail d'un amis » (`865:17783`), frames F7 (`967:5361`) and F8
(`967:5583`), variant `Selected=Échanges` of `Profile / Tabs` (`875:5287`).

## What it does

- **Four tabs on a friend's profile**: « Inventaire • N » | « Listes • N » | « Échanges • N » | « Présentation »
  (« Transactions • N » in English). « Prêts » was considered and dropped: the tab also holds sales and gifts.
- **My own profile has three**, without Échanges: there is no Échange with oneself. Someone whose books are closed
  to me still has no tabs.
- **The count** is every Échange with that friend, in both directions (they own the copy or I do), in any state.
- **A tinted dot after « Échanges • N »** while one of those Échanges is unread on my side. It follows the same
  rule as the dot on a row (see « Not done » below).
- **The page has two sections**, as « Toutes les transactions » has: « En cours » (requested, accepted, confirmed),
  then « Terminés » (returned, declined, cancelled). Each is sorted by last action, newest first. An empty section
  is not shown.
- **The rows are `TransactionCellView` unchanged**, sentence included (« Vous souhaitez l'emprunter à Camille »),
  even though it repeats the name and stays in the present tense for a finished Échange. One cell for the whole app.
- A row opens the Échange screen on the profile's navigation path. Back returns to the Échanges tab.
- **No Échange**: the tab is still shown, as « Échanges • 0 ». The page holds an empty state, no button, glyph
  `arrow.left.arrow.right`: « Aucun échange avec <name> », then « Quand l’un·e de vous demandera un livre à
  l’autre — pour l’emprunter, l’acheter ou le récupérer —, l’échange apparaîtra ici. »
- **The tab row scrolls only when it does not fit.** On a friend's profile the capsules have 8 pt of horizontal
  padding (`.small`) instead of 12 pt, so the four tabs fit a phone at the default text size. At large text sizes
  the row scrolls sideways, and the selected tab is scrolled into view, whether tapped or reached by a swipe. While
  the row scrolls, a word is picked by a tap and the capsule cannot be picked up: the lens's drag
  ([0075](0075-lens-tabs-and-a-lists-pager.md)) would block the scroll. The capsule still follows the pager.
- A list's Livres | Présentation is unchanged: it keeps 12 pt capsules and the lens.

## Technical surface

- **The data is local.** `TransactionModel.syncTransactions` already stores all my Échanges. The tab reads them
  with a plain `@Query` and keeps those whose `owner` or `requester` is the friend. No new endpoint.
- `Model/Transaction/TransactionSections.swift`: splits Échanges into `current` and `finished`, each newest
  last action first, optionally limited to those with one reader. It also answers `count`, `isEmpty` and
  `hasUnread(by:)`. « Toutes les transactions » (`AllTransactionsView`) now uses it too, with no reader.
- `Features/Transactions/TransactionsSection.swift`: one section of rows under its header, each row a
  `NavigationLink` to `NavigationDestination.transaction`, nothing when empty. Shared by `AllTransactionsView`
  and the new tab. Rows carry the identifier `e2e.transactions.row` on both screens. `AllTransactionsView` keeps
  its headers « Transactions en cours » / « Transactions finies ».
- `Features/Community/UserTransactionsTab.swift` (the page) and `UserTransactionsTabTitle.swift` (« Échanges • N »
  and the dot), next to `UserListsTab` and `UserPresentationTab`.
- `UserProfileTab` gains `.transactions` between `.lists` and `.presentation`. `UserProfileTab.pages(isMine:)`
  gives four pages on a friend's profile, three on mine. `UserDetailView` passes that list to the pager and the
  header.
- **The tab components take their tabs as a list.** `TabPager`, `LensTabPicker` and `LensTabLabels` take
  `tabs: [Tab]`, by default every case of the enum, so a list's pager is unchanged. `TabPager` rebuilds its pages
  when the list changes. `ProfileScrollOffset` blends the header's fold over the pages it is given (`among:`):
  Présentation is the fourth page on a friend's profile and the third on mine.
- `LensTabPicker` wraps its row in a `ViewThatFits`: the row as before, or a horizontal `ScrollView` with a
  `ScrollViewReader`. A `SpatialTapGesture` picks a word in the scrolling row, through `LensTabTrack.index(at:)`.
  `wordPadding(_:)` sets the room around each word; the profile asks for `.small`.
- `UserTransaction.isRead(by:)` (`UserTransaction+ReadStatus.swift`) holds the rule `TransactionCellView` had
  inline, so the row and the tab's dot share it. Behaviour unchanged.
- `UserTransaction.mock(...)` for previews and tests.
- Strings, fr and en: `user.tab.transactions`, `user.tab.transactions %lld`,
  `user.tab.transactions.accessibility %lld`, `user.tab.transactions.unread`, `user.transactions.current`,
  `user.transactions.finished`, `user.transactions.empty.title %@`, `user.transactions.empty.message`.
- Tests: `TransactionSectionsTests` (the reader filter in both directions, no reader, ongoing apart from finished,
  newest first, empty, the unread rule on my side only), `UserProfileTabTests` (four pages for a friend, three for
  me), `LensTabTrackTests` (a tap picks the word under it), `ProfileHeaderCollapseTests` on the new signature.

## Not done / owed

- **`isRead` may be inverted.** The rule says "read" when my side's server `read` flag is `false`, while the app
  creates its requests with `requester: true`. The dot may show on Échanges that are read, on the rows and on the
  tab. Kept as is; to check against inventaire.io.
- **SwiftLint against CLAUDE.md**: `explicit_type_interface` makes `UserTransactionsTabTitle` write
  `@Environment(UserModel.self) private var userModel: UserModel`, which CLAUDE.md's "no type annotation on SwiftUI
  environments" forbids. One of the two has to give.
- Members of `TabPager` and `LensTabPicker` were reordered for SwiftLint, so their baseline entries are stale. The
  baseline was not grown.
- Seen on the simulator (iPhone 17, iOS 26.4, light): a friend with one ongoing Échange shows « Inventaire • 138 ·
  Listes • 2 · Échanges • 1 · Présentation » with the dot, four tabs fitting, and « En cours » alone. Not seen:
  finished Échanges, both directions, a row and back, the empty state, the swipes and the header's fold over four
  pages, the largest text size, my own profile, dark mode, a list's Livres | Présentation. e2e was not run.
- Android follows in its own task.
