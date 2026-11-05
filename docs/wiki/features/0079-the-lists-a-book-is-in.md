# The lists a book is in, on the Fiche livre

Shipped on 2026-11-05, iOS only (issue #34). Before this change, nothing on the Fiche livre said that the book was in a
list: you had to open each list to find out. The Figma proposal is the second row of `Fiche livre · Données
bibliographiques` (`744:2382`): `N1` (`944:7954`), `N2` (`944:8280`) and the spec (`945:8188`).

## What it does

- **The section.** « Dans les listes » sits between « Dans mon inventaire » and « Données bibliographiques ». It has one
  row for each list of works that holds the edition's work. Each row is the Listes tab's row: fanned covers, count,
  name and explanation.
- **Whose lists.** The section shows my lists and my friends' lists. A friend's row starts its count line with the
  friend's picture and name (« Rémi • 9 œuvres »).
  - A stranger's list is left out, even when it is in the store because their profile was opened.
  - A list of authors is left out. Its place would be the author's screen.
- **Order.** All lists are mixed, the most recently updated first (`updated`, else `created`). Olivier chose this over
  the Listes tab's « mine, then my network », which is what the mockup shows.
- **No list, no section.** There is no header and no empty card. There is no « Ajouter à une liste » row either: the
  « … » menu already does that ([0016](0016-create-a-list-or-shelf-from-a-book.md)).
- **A recueil.** When two of its works are in one list, the list shows once. It opens on the first of those works in
  the list's order.
- **Opening a list.** A tap pushes the Liste on the current tab, on its Livres page.
  - The cover flow starts on the list's first book. About 300 ms later it springs, in 0.4 s, to the book you came
    from.
  - Once that book is centred, its cover gets a `foreground/tinted` halo, which fades in 1.2 s. The halo is a 2 pt
    stroke 5 pt out from the cover, plus a 14 % 8 pt stroke 11 pt out.
  - The arrival gives one selection haptic, and VoiceOver moves to the book's title.
  - This happens once per opening. A swipe or a tap elsewhere puts the halo out at once.
- **Reduce Motion.** The list opens directly on the book, and the halo only fades.
- **A friend's list** opens read-only, as it does from the Listes tab ([0068](0068-lists-in-my-network.md)).
- **Back** returns to the Fiche livre, at the same scroll position.
- **The same list twice.** From a list you can open a book, then the same list again from « Dans les listes ». The list
  is pushed a second time. The navigation path is not inspected.

## Technical surface

- `Features/Book/BookListsSection.swift`: two queries.
  - A `@Query` of `EntityListItem` whose `uri` is one of `Edition.workUris`, so the section follows an add or a
    removal made elsewhere (ADR 0001).
  - A `@Query` of the friends.
  - Nothing new goes to the server: the lists are already in the store, mine and my network's since 0068.
- `Model/Lists/BookListEntry.swift`: one row (`list`, `owner`, `focusURI`) and the pure
  `entries(items:myUserId:friends:)`, which filters, deduplicates (focus = lowest `ordinal`) and orders —
  `Tests/BookListEntryTests.swift`.
- `Model/UserData/EntityList+Friend.swift` (`friendCreator(myUserId:friendsById:)`),
  `EntityList+LastChanged.swift` (`updated ?? created`) and `User+ById.swift`: the friend rule, the order and the
  lookup, shared with `ListsTabSections`.
- `NavigationDestination.entityList(id:focusURI:)` — `focusURI` defaults to nil, the `id` carries it; passed to
  `EntityListDetail` then `ListCoverFlowScreen`.
- `Model/Lists/ListArrivalFocus.swift`: the pure state machine of the arrival (`waiting` → `arriving(scroll|jump)` →
  `highlighted` → `done`), once per screen, even when the focus reaches `uris` late; a selection moved by the user
  clears the halo — `Tests/ListArrivalFocusTests.swift`. A Reduce Motion jump is applied in `onAppear`, so the first
  book never shows for a frame.
- `Features/Lists/ListCoverHalo.swift`: the halo, drawn by `ListCoverFlowItem` through `highlighted(_:)`;
  `ListElementsPage` and `ListCoverFlowView` pass it on through `highlighting(_:)`.
- **One haptic per arrival.** The cover flow's `.sensoryFeedback(.selection)` now skips the first selection
  (nil → first) on every list, so opening a list no longer ticks. When the arrival does not move the selection (the
  book is the list's first, or a jump from nothing), `ListArrivalFocus.landingFeedbackURI` has the screen tick as the
  halo lights. The two rules depend on each other.
- `Localizable.xcstrings`: `book.in_lists`, « Dans les listes » / « In lists ».

## Not done

- **A typed environment.** `@Environment(\.accessibilityReduceMotion) private var reduceMotion: Bool` carries a type,
  against CLAUDE.md. SwiftLint's `explicit_type_interface` fails the build without it. The rule conflict is open.
- **Android**: not ported.
- **Testing**: installed on an iPhone. The arrival timing and the VoiceOver focus have not been checked on a device.
  e2e was not run.
