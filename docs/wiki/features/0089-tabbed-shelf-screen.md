# An étagère in two tabs, and books added to it in one go

Shipped on 2026-11-06, iOS only (issue #51, PR #52, then a review round). The étagère screen was a plain list of its
books, and a book reached an étagère one at a time, from its « … » menu ([0006](0006-shelf-membership.md)). It now
borrows a list's two tabs ([0073](0073-a-lists-presentation-tab.md), [0075](0075-lens-tabs-and-a-lists-pager.md)) and
adds books by the batch. It was first tried beside the old screen, behind an « Étagères (v2) » section of the
Inventaire; once judged, it replaced it and the section went.
The Figma maquette is the section `Étagère détails · V2` (`973:8195`) of the `Inventaire` page: `E1` → `E5`, `E3b`,
`E3c` and the panel `Spec · Étagère détails · V2`.

## What it does

- **The way in.** An étagère's paper label, in my carousel or in a friend's on their profile
  ([0019](0019-a-friends-shared-shelves.md)), opens this screen.
- **The screen.** The étagère's name inline in the navigation bar, the pencil (mine only), then the tabs « Livres • N »
  | « Présentation », changed by a touch or a swipe. No tab bar: since this change, every screen pushed from the
  Inventaire hides it, as in Réseau and Listes ([0088](0088-tab-bar-hidden-on-pushed-screens.md)).
- **« Livres ».** The étagère's books in an inset grouped list, newest first. A touch opens the Fiche livre; a
  swipe takes the book off the étagère (mine only). « Ajouter des livres » is a primary button pinned at the bottom,
  like a form's « Enregistrer », on « Livres » only and on my étagère only. Empty → « Cette étagère est vide ».
- **« Présentation ».** The description, links live, or « Cette étagère n'a pas de description »; then Visible par
  (Privé, Ami·es, Public), Créée le, and Modifiée le only when the étagère changed after its creation.
- **« Ajouter des livres ».** A sheet titled « Ajouter à « <étagère> » », like a list's search sheet, with my books
  not yet on the étagère, newest first, a checkbox each; the whole row
  ticks. A search field « Titre ou auteur·ice », always visible, filters by title or author; a book ticked then hidden
  by the search stays ticked and counted. « Ajouter N livres » is pinned at the bottom, « Ajouter 0 livre » and greyed
  when nothing is ticked. No match → « Aucun de tes livres ne correspond à « … » »; every book already there → « Tous
  tes livres sont déjà sur cette étagère »; no book at all → « Tu n'as pas encore de livre ». The `xmark` closes
  without adding.
- **The write.** « Ajouter N livres » sends one `POST /api/shelves?action=add-items` with every ticked book and closes
  the sheet. The books are on the étagère before the answer; a refusal takes them off again and reaches the SnackBar
  (ADR 0001).
- **A friend's étagère** is the same screen, read-only: no pencil, no swipe, no button.
- **Deleting the étagère** from the pencil's form pops the v2 screen back to the Inventaire.

## Technical surface

- `Features/Shelves/Detail/`: `ShelfDetailView` (a `TabPager` with `ShelfDetailTabPicker` laid over it, as
  `ListCoverFlowScreen`), `ShelfBooksPage`, `ShelfBookRow`, `ShelfPresentationPage`, `ShelfAddBooksSheet`,
  `ShelfAddBookRow`, `ShelfDetailTab`, `ShelfPreviewStore`. The old plain-list `ShelfDetailView` is gone.
- **Routing.** `NavigationDestination.shelf(id:)` is unchanged and pushes the new screen. While both screens lived side
  by side, a `layout` parameter on that case chose one, because the SwiftLint baseline freezes the dispatch's
  complexity; it went with the old screen.
- **The body is a `ZStack`, not a `Group`.** A `Group` hands its modifiers to its children; once the étagère was
  deleted it had none, the edit sheet went with them, its `onDismiss` never ran and the screen stayed blank.
- **« Modifiée le ».** On the simulator SwiftData read a nil `updated` back as 1 January 2001, so the row only shows a
  date later than `created`.
- **Search.** `.searchable(.navigationBarDrawer(displayMode: .always))` as `ListAddSearchView`. It matches the
  edition's title and displayed author names with `localizedStandardContains`, not `InventoryItem.searchIndex`, which
  also holds my own username and would match every book.
- **Batch write.** `ShelfModel.addItems(_:to:modelContext:)` drops the books already there and goes through the same
  `membershipWrite` as `removeItem`, gate included; the one-book menu calls it with one book. The revert removes the
  ids captured before the write, and only the étagère is a subject, so a book deleted during the round trip does not
  cancel the revert of the others. `ShelfModelAddItemsTests` covers one call with only the new books, and the revert
  with its SnackBar.
- **Tab bar.** `ShelvesView` applies `hidesTabBarWhenPushed(on:)` to its `NavigationStack`
  ([0088](0088-tab-bar-hidden-on-pushed-screens.md)).

## Not done

- Dark mode not designed; Android not ported.
- Seen on the simulator before the maquette's second pass: the tabs, « Présentation », the sheet, two books added and
  still there after relaunch, deletion popping the screen. Not seen: the pinned button, the search, a friend's
  étagère, the tab bar leaving the Inventaire, the screen reached from the carousel. e2e not run; its étagère step only
  needs the nav bar's « Modifier », still there.
