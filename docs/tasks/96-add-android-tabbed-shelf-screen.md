---
issue: 96
status: todo
wiki: [[features/0089-tabbed-shelf-screen]], [[features/0073-a-lists-presentation-tab]], [[features/0077-android-catches-up-with-1-9-0]], [[adr/0001-swiftdata-reactive-optimistic]]
note: Rattrapage iOS 1.10.0 (feature 0089). ShelfScreen is a plain list; AddBooksToShelfSheet toggles one book per tap.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0089](../wiki/features/0089-tabbed-shelf-screen.md). Builds on #95: no tab bar on a screen pushed from the Inventaire, so « Ajouter des livres » takes the bottom.

- **Screen.** `ShelfScreen` (`ui/inventory/`) becomes the étagère's name in `RecitTopBar`, the pencil (mine only, `ShelfFormSheet`, `onDeleted` pops as now), then `CapsuleTabs` « Livres • N » | « Présentation » over a `HorizontalPager`, changed by a touch or a swipe — the pattern of `EntityListScreen` (`ListDetailTab`). Reached from my carousel and from a friend's on their profile.
- **« Livres ».** The étagère's books, newest first; a touch opens the Fiche livre; on mine a swipe takes the book off (`RemovableRow`, unchanged). « Ajouter des livres » is a primary button pinned at the bottom, on « Livres » only, on mine only — the `ListAddBar` placement.
- **Empty « Livres »: a centred empty state**, shelf icon + « Cette étagère est vide », no action (the pinned button is the action). Same on a friend's étagère, without the button. (Olivier's pick, in the direction of iOS #88.)
- **« Présentation ».** The description with live links, or « Cette étagère n'a pas de description »; then Visible par (Privé, Ami·es, Public), Créée le, and Modifiée le only when later than Créée le. `ShelfHeader` goes.
- **« Ajouter des livres » replaces `AddBooksToShelfSheet` as iOS's sheet.** Titled « Ajouter à « <étagère> » », close button, a search field « Titre ou auteur·ice » always visible, my books **not yet on the étagère**, newest first, a checkbox each, the whole row ticks. A book ticked then hidden by the search stays ticked and counted. « Ajouter N livres » pinned at the bottom; « Ajouter 0 livre » disabled when nothing is ticked. Empty texts: « Aucun de tes livres ne correspond à « … » », « Tous tes livres sont déjà sur cette étagère », « Tu n'as pas encore de livre ». No removal in the sheet: removal is the swipe.
- **Search** matches the edition's title and displayed author names, case and accent insensitive — not my own username.
- **Write: one optimistic `add-items`.** « Ajouter N livres » closes the sheet; the books are on the étagère at once; one `POST /api/shelves?action=add-items` with every ticked book (already-there ones dropped); a refusal takes them off again and reaches the SnackBar (ADR 0001). A `ShelfRepository.addItems(shelfId, itemIds)` through `OptimisticRunner`; the one-book menu calls it with one book; the awaited `addItemsNow` stays for the sort flow.
- **A friend's étagère** is the same screen, read-only: no pencil, no swipe, no button.

## Acceptance criteria

- My carousel → an étagère's label: name in the bar, pencil, « Livres • N » | « Présentation », no tab bar, « Ajouter des livres » pinned at the bottom.
- Swiping left/right or touching the capsule changes the tab; the button shows on « Livres » only.
- « Présentation » shows the description (links tappable) or « Cette étagère n'a pas de description », then Visible par, Créée le; Modifiée le only after an edit.
- Empty étagère: centred shelf icon + « Cette étagère est vide », no action in the empty state.
- « Ajouter des livres » → the sheet lists only my books not on the étagère; ticking 2, searching for something that hides one, the button still reads « Ajouter 2 livres ».
- Nothing ticked: « Ajouter 0 livre », disabled.
- « Ajouter 2 livres »: the sheet closes, both books are on « Livres » at once, count « Livres • N+2 », one `add-items` request with both ids (unit test).
- Server refuses (unit test): both books leave the étagère, SnackBar shown.
- Swipe on a book removes it from the étagère.
- Pencil → delete the étagère: the screen pops back to the Inventaire.
- A friend's profile → their étagère: same tabs, no pencil, no swipe, no button.
