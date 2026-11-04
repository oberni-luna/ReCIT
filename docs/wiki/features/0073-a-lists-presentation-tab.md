# A list's description, under a Présentation tab

Shipped on 2026-11-01, from option B of the Figma proposal `Liste détails · Description de la liste` (`909:1465`,
frames B1 `909:1616` and B2 `909:1676`). The list's screen showed its description nowhere; four placements were
drawn, and B was chosen. No PRD and no issues: one slice.

## What it does

A list of works or of authors opens, under its navigation bar, on two tabs in the labels of a reader's profile:
« Livres • 8 » (« Auteur·ices • 3 » for a list of authors) and « Présentation », the selected one in a glass
capsule. They stay pinned under the bar, as on a reader's profile, the list scrolling under them. A touch changes
the tab, and the capsule glides to it; there is no swipe between them, since the horizontal swipe belongs to the
cover flow.

- **Livres** is the screen as it was (feature 0060): the cover flow, the selected element, its comment, « Déplacer
  dans une autre liste », « Retirer de la liste », and « Ajouter un livre » in place of the tab bar.
- **Présentation** holds the description, whole, in one card, any address in it opening; then a card of what the
  list is — « Type » (Œuvre, Auteur·ice), « Visible par » (Moi seul·e, Mes amis, Mes groupes, Mes amis et mes
  groupes, Tout le monde), « Créée le », and « Modifiée le » when inventaire.io sent a date. A list without a
  description says so (« Cette liste n'a pas de description »). « Ajouter un livre » steps aside here.

A friend's list, read-only, has the same two tabs.

## Technical surface

- **`ListDetailTab`** (`Features/Lists/`) — `.elements`, `.presentation`.
- **`ListDetailTabPicker`** — the labels of `UserProfileTabPicker` (`action200`, 12 pt of padding, `glassCapsule()`),
  the capsule moved by `matchedGeometryEffect` under a `.snappy` animation rather than following a pager.
  VoiceOver reads « Livres, 8 », without the bullet.
- **`ListPresentationPage`** — two sections; the description goes through `UserPresentationTab.linked(_:)`, the
  values under their captions through `withLabel(label:)`, as in the list's form.
- **`ListVisibilityLabel.label(for:)`** — inventaire.io's visibility keys in words: `public` wins over the rest,
  `friends` and `groups` are named apart or together, none is « Moi seul·e ».
- **`listDetailTabsBar(_:)`** (in `ListDetailTabPicker.swift`) — pins the tabs under the navigation bar, 2 pt
  under it and 8 pt above the list: a `safeAreaBar(edge: .top)` with the soft scroll edge from iOS 26, a
  `safeAreaInset` on the bars' material before it — `formActionBar`'s pattern, at the top.
- **`ListCoverFlowScreen`** — what used to be the whole list is `elementSections`; the add bar shows only on
  Livres. The tab bar stays hidden on my lists under both tabs, so it does not come and go with the tab.
- Strings: `list.tab.{works,authors} %lld` and their `.accessibility`, `list.tab.presentation`, `list.tabs`,
  `list.presentation.empty`, `list.info.{type,visibility,created,updated}`,
  `list.visibility.{private,friends,groups,friends_and_groups,public}`, fr and en.
- **`ListVisibilityLabelTests`** — the French label of every combination.

## Notable decisions

- **B over A** (the description on two lines above the cover flow), which the proposal recommended: B also gives
  the list's type, visibility and dates a place, and costs the cover flow only the tabs' row.
- **A picker of its own, not `UserProfileTabPicker` made generic.** The profile's capsule follows a
  `UIPageViewController`'s offset; here nothing pages, so the shared part is the look, not the mechanism.
- **The type in the singular** (« Œuvre »), the words of the list's form, rather than the mock-up's « Œuvres ».
- **No way to edit from Présentation.** The navigation bar's pencil already opens the form, description included.

## Not done

- Seen on a phone in dark, on Livres, before the tabs were pinned: they were then the list's first row, scrolling
  away, with the list's top margin and section spacing between them and the title. Pinned, they were installed
  on the phone but not looked at; light, Présentation and iOS 18 unseen.
- Android not done. The proposal's dark mode was never drawn. e2e not run.
