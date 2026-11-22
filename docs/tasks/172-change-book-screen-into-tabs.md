---
issue: 172
status: to-test
wiki: [[features/0029-full-screen-cover]], [[features/0066-a-friends-profile-tabs-as-pages]], [[features/0067-a-friends-profile-presentation-tab]], [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0079-the-lists-a-book-is-in]], [[features/0080-a-private-note-on-my-copy]], [[features/0089-tabbed-shelf-screen]], [[design-system/figma-library]]
note: Figma « F · Fiche livre — en-tête qui se replie et trois capsules », file S7IvC6GvlcUFe5IgbtvQq6, section 1179:2811 (frames F1–F5 1180:3116, 1180:3195, 1180:3358, 1180:3522, 1180:3676; component Book / Header 1179:2907, states Rest / Folded). Builds on #173. Grilled 2026-11-22.
created: 2026-11-22
---

## Context / Decisions

> Figma « F · Fiche livre — en-tête qui se replie et trois capsules »: le pattern du Profil d'un ami appliqué à la Fiche livre. Couverture et titre en grand sur la couverture floutée, repliés au défilé, capsules épinglées. Présentation / Mon exemplaire / Dans le réseau • N, changées d'un toucher ou d'un glissement (TabPager).

Today the Fiche livre (`BookDetailView`) is one long list: header, summary and authors, other editions, community copies, my copy, lists, bibliographic data. It becomes the Profil d'un ami's pattern: a large header that folds as the page scrolls, and three capsules, each a page of its own in a `TabPager`.

1. **Built on #173.** The folding header and the pages come from the container #173 extracts into `Features/Components/`. The Fiche livre gives it its header and its three pages; no second copy of the scroll code.
2. **Header, at rest** (`Book / Header`, `State=Rest`): the cover large and centred over the blurred cover, the title in `title` style, then one line « auteur·ices · sous-titre » (« Alexandre Dumas · Tome I »), then the three capsules. The author line is not tappable: an author opens from their row in Présentation. Tapping the cover still opens the Plein écran (0029).
3. **Header, folded** (`State=Folded`, F4): a small cover, the title on one line, the capsules pinned under the navigation bar, over a progressive blur with a hairline. Folds and snaps like the profile (never half folded).
4. **Capsules.** « Présentation » | « Mon exemplaire » | « Dans le réseau • N », the profile's lens capsules, changed by a touch or a swipe. The Fiche livre always opens on Présentation.
5. **Présentation** (F1): summary with genres, authors, other editions, then « Données bibliographiques » and its reassurance line, as today. `e2e.book.otherEditions` stays on this page.
6. **Mon exemplaire** (F2, F5):
   - **« Dans mon inventaire »**, when I own the edition: « Ce que j'en pense », « Ce que je garde pour moi », the status and creation date (`BookMyCopySection`, unchanged).
   - When I don't (F5): « Ce livre n'est pas dans votre inventaire. Ajoutez-le pour y noter ce que vous en pensez, et pouvoir le prêter. » and a « Ajouter à mon inventaire » pill, running the same action as the « … » menu's entry. Once added, the page shows my copy.
   - **« Dans mes listes »**: my lists of works holding the book, then always a last row « Ajouter à une liste », opening the list menu the « … » already has (`EntityListMenu`).
7. **Dans le réseau • N** (F3):
   - **« Dans la communauté »**: the other readers' copies, as today (`FriendItemRow`, long press to ask).
   - **« Dans les listes de mes ami·es »**: my friends' lists of works holding the book.
   - **N** = those copies + those lists. N = 0 → the capsule stays, without a count, and the page shows an empty state: « Aucun·e de vos ami·es n'a ce livre, ni dans son inventaire ni dans une liste. »
8. **`BookListsSection` splits** between Mon exemplaire (mine) and Dans le réseau (friends'), same rows and same tap (the Liste springing to the book, 0079).
9. **Unchanged.** The « … » menu and its toolbar placement, `BookResolvingView` while resolving, the absences and the retry, the keyboard « OK » over the notes, readable width on wide screens (0053), the tab bar rules on push (0088, 0089). The Fiche livre keeps its form ground and cards (0054).
10. **Wording.** « Mon exemplaire » is written: the glossary row Livre drops `exemplaire` from Also (decided in this grill). « Dans la communauté » is the existing string and stays, though the glossary lists « Communauté » as Never for Groupe: out of scope.
11. **iOS only.** Android's Fiche livre is not changed here.

## Acceptance criteria

- Opening a book shows the large centred cover, the title, « auteur·ices · sous-titre » and the three capsules, Présentation selected.
- Présentation lists the summary with genres, the authors, « Autres éditions » when there are some, and « Données bibliographiques » last.
- Scrolling Présentation folds the header: small cover, title, capsules pinned under the bar over a blur; releasing halfway lands folded or unfolded.
- Swiping left goes Présentation → Mon exemplaire → Dans le réseau; tapping a capsule goes there too.
- On a book I own, Mon exemplaire shows my two notes and the status; editing a note and tapping « OK » saves it as before.
- On a book I don't own, Mon exemplaire shows the sentence and « Ajouter à mon inventaire »; tapping it adds the book and the page shows my notes and status.
- « Dans mes listes » shows my lists holding the work, and always ends on « Ajouter à une liste », which opens the list menu.
- Dans le réseau shows the other readers' copies and my friends' lists holding the work; the capsule reads « Dans le réseau • N » with N their total.
- On a book nobody in my network has, the capsule reads « Dans le réseau » and its page shows the empty sentence.
- Tapping a list row opens the Liste on that book, from either tab.
- Tapping the cover at rest opens it full screen.
- The « … » menu works from every tab; removing the book still pops the screen.
- The Profil d'un ami behaves as before.

## Implementation

stacked on: wa/173-extract-folding-header-pager @ 6db50a08

- `BookDetailView` hosts `FoldingHeaderPager` (#173): sheets, creation sheet, measured title/byline heights, genre enrichment.
- `Features/Book/Header/`: `BookHeader` (rest + folded, reads the fold), `BookHeaderMetrics` (cover 256 → 48, 62 pt rise, title to one `title50` line, byline), `BookHeaderCover` (Plein écran via `.enlargeablePhoto`, slide-up like the profile: a zoom source over `TabPager` vanishes), `BookHeaderCoverPlaceholder`, `BookHeaderTitle` (large title fades out over the first half of the fold, one-line copy fades in over the second), `BookHeaderByline`, `BookHeaderBackdrop`.
- `Features/Book/Tabs/`: `BookTab`, `BookTabPicker`, `BookNetworkTabLabel`, `BookPresentationPage`, `BookOtherEditionsSection`, `BookMyCopyPage` (owns the notes' `@FocusState` and keyboard « OK »), `BookAbsentCopySection`, `BookNetworkPage`, `BookNetworkEmptyState`.
- `Model/Books/BookNetworkHoldings`: others' copies + friends' lists, one count for capsule and page. `BookListEntry.isMine` splits the lists; `BookListEntriesReader` holds the queries, `BookListsSection` is now a plain section.
- `AddToInventoryButton`: shared by the « … » menu and the F5 pill. `EntityListMenu` gains `.title(_:)` for the « Ajouter à une liste » row (shown when the edition has one work, as the menu).
- `FoldingHeaderPage` (Components): a page shorter than the fold gets bottom room (`FoldingHeaderCollapse.bottomRoom`) so it can always fold; long pages get none.
- 12 strings fr + en; `book.in_lists` removed. New ids: `e2e.book.tab.*`, `e2e.book.myCopy.addToInventory`, `e2e.book.myLists.addToList`.
- Build ✅ (SwiftLint) · tests ✅ BookListEntryTests, BookNetworkHoldingsTests, FoldingHeaderCollapseTests: 18 passed.
- Notes: `BookResolvingView` still shows the old left-aligned header while resolving, so the header jumps when the edition lands. Empty network page: sentence alone, no Figma frame. `e2e.book.tab.*` may be swallowed by `LensTabLabels`' `.accessibilityElement(children: .combine)`, unconfirmed.

- round 3 (feedback): `TabPager.Coordinator.follow` defers the name-driven turn to the next main-actor turn (`Task { @MainActor … }`, dropped if the selection moved meanwhile); `turn` ends editing before `setViewControllers`. Build ✅ · tests ✅ 1464 passed.

- round 4 (feedback): `FoldingHeaderPager` lets the keyboard reach the pages — `TabPager` ignores the container safe area only (`.ignoresSafeArea(.container)`), not the keyboard, so each page's list brings the focused note above it. Build ✅ · tests ✅. Known: after « OK » the header can rest half folded until the next touch (keyboard scrolls never go through `FoldingHeaderSnapBehavior`).

## Review

## Verification

Simulator iPhone 17, « Le Monde qui n'est pas » (my copy, also OlivierB's, in his « Livres à lire »):
- ✅ rest header: large centred cover, two-line title, « Frank Tashlin », capsules, Présentation selected
- ✅ Présentation: authors, « Données bibliographiques » last (no summary or other editions on this book)
- ✅ tap « Mon exemplaire » → notes and status; swipe → Dans le réseau
- ✅ « Dans mes listes » ends on « Ajouter à une liste »
- ✅ Dans le réseau: OlivierB's copy, « Livres à lire » under « Dans les listes de mes ami·es », capsule « Dans le réseau • 2 »; L'étranger reads « Dans le réseau » without a count
- ✅ round 2: one swipe up on the short Mon exemplaire lands folded (small cover, one title, capsules pinned); swipe down unfolds
- ⚠️ round 1 seen stuck half folded on the first swipe right after a tab change; not reproduced after round 2
- not run: note save with « OK », F5 pill (not tapped, would write), list row → Liste, cover full screen, « … » from each tab and removal, network empty page, profile regression

- round 3 (feedback): keyboard open on « Ce que j'en pense », tap « Présentation » → keyboard closes, page turns, no freeze ✅; keyboard on « Ce que je garde pour moi », tap « Dans le réseau » → same ✅ (simulator iPhone 17). Not run: a list's comment with the keyboard open; on device.

- round 4 (feedback): focus « Ce que j'en pense » then « Ce que je garde pour moi » with the header at rest → page scrolls, field and cursor above the keyboard ✅; « OK » closes it ✅; header then rests half folded, back to rest at the next touch ⚠️ (simulator iPhone 17). Not run: on device, a long Mon exemplaire, friend profile regression.

## Feedback

### Round 3 — 2026-11-22
- Asked: « Mon semble avoir crash, tu peux regarder les logs ? » → « Oui corrige ». Crash report from the iPhone: watchdog `0x8BADF00D` (scene-update, 10 s), AttributeGraph cycle. A capsule tapped while the keyboard is open on Mon exemplaire: `TabPager.updateUIViewController` → `follow` → `turn` → `setViewControllers(animated:)` removes the page, its `UITextView` resigns, the keyboard hides and re-enters the SwiftUI update.
- Triage: defect (criteria unchanged). Implementer: concurrency change.
- Changes: `ReCIT_iOS/Features/Components/TabPager.swift` — turn by name deferred out of the SwiftUI update; `endEditing(true)` before the turn.
- Review: deferred → /wa-validate. Verify: ✅ on the simulator, both fields. Rule captured: none.

### Round 4 — 2026-11-22
- Asked: « quand je mets le focus sur un des champs de text de "dans mon inventaire" il faudrait que l'écran scroll pour que je vois le curseur. La c'est pas le cas »
- Triage: defect — criterion « editing a note … as before ». Implementer (cause unknown), then main thread.
- Cause: `contentInsets.bottom` stayed at 34 on focus — `.ignoresSafeArea()` on `TabPager` covered the keyboard region too, so the pages never knew the keyboard was up. A first guess (the snap behaviour pulling the scroll back) was tried and dropped: keyboard scrolls never reach `updateTarget`.
- Changes: `ReCIT_iOS/Features/Components/FoldingHeaderPager.swift` — `.ignoresSafeArea(.container)` and its comment (`inline`).
- Review: deferred → /wa-validate. Verify: ✅ simulator, both notes; ⚠️ half fold after « OK » until the next touch. Rule captured: none.
