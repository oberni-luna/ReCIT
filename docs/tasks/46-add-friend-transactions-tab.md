---
issue: 46
status: todo
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

## Review

## Verification

## Feedback
