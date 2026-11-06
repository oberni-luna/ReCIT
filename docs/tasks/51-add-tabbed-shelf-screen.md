---
issue: 51
status: todo
wiki: [[features/0001-shelf-carousel-and-creation]], [[features/0019-a-friends-shared-shelves]], [[features/0073-a-lists-presentation-tab]], [[features/0075-lens-tabs-and-a-lists-pager]], [[design-system/figma-library]]
note: Écran étagère v2, maquetté dans Figma (section « Étagère détails · V2 », 973:8195) ; un premier jet du code est déjà sur cette branche.
created: 2026-11-06
---

## Context / Decisions

> Dans la page "Inventaire" peux-tu faire une nouvelle section pour une v2 de l'écran de détail des étagères. Je veux un écran avec 2 onglets comme pour les listes : « Livres • <nb de livres> » : la liste des livres dans une List .insetGrouped ; « Présentation » : la description de l'étagère et ses propriétés comme pour les listes. En bas de la liste des livres un bouton « Ajouter des livres » qui ouvre en sheet la liste de mes items avec un checkbox pour sélectionner les livres à ajouter et un bouton en bas en safe area « Ajouter <nb de livres selected> livres ». Le bouton « Ajouter n livres » ajoute les livres dans l'étagère et dismiss l'écran.

- **Maquette** : Figma, page `Inventaire`, section `Étagère détails · V2` (`973:8195`), écrans E1 → E5 et panneau Spec. Elle fait foi.
- **Tried side by side**: the current shelf screen (`ShelfDetailView`) stays. The Inventaire gets a section « Étagères (v2) » under the carousel, one row per étagère of mine (name, book count), opening the v2 screen. The carousel keeps opening the current screen.
- **A friend's étagère opens the v2 screen directly** from their profile carousel, read-only: same tabs, no pencil, no swipe, no « Ajouter des livres ».
- **Routing**: no new `NavigationDestination` case — the SwiftLint baseline freezes its complexity. `.shelf(id:)` takes `layout: ShelfScreenLayout` (`.list` default, `.tabs`).
- **Screen**: built as a list's (`ListCoverFlowScreen`): `TabPager` + `LensTabPicker` under the nav bar, « Livres • N » | « Présentation ». **No tab bar** on this screen.
- **Livres**: the étagère's books in an inset grouped list (`DesignSystem.FormList`), newest first, `InventoryCell`. Tap → Fiche livre. Trailing swipe takes the book off this étagère (existing optimistic `removeItem`), mine only.
- **« Ajouter des livres »**: a `Button / Large` primary pinned in the bottom safe area like a form's « Enregistrer » (`formActionBar`), under « Livres » only, mine only. Not a row at the end of the list.
- **Présentation**: description (links live) or empty state « Cette étagère n'a pas de description », then Visible par (Privé / Ami·es / Public), Créée le, Modifiée le — the last only when later than creation (SwiftData read a nil `updated` back as 1 January 2001 on the simulator).
- **Sheet « Ajouter des livres »**: my books not already on the étagère, newest first, a checkbox per row, the whole row toggles. Close with the `xmark` like every other sheet.
  - Search field « Titre ou auteur·ice », always visible under the sheet's bar (`.searchable`, `.navigationBarDrawer(displayMode: .always)`), filters by title or author with `localizedStandardContains`. Ticks survive filtering and still count.
  - No match → « Aucun de vos livres ne correspond à « … » ». All my books already there → « Tous vos livres sont déjà sur cette étagère ».
  - Pinned button « Ajouter N livres » (plural); at 0 it reads « Ajouter 0 livre », disabled.
- **Write**: one optimistic `POST /api/shelves?action=add-items` with every ticked book (`ShelfModel.addItems`), books on the étagère before the answer, sheet closes; refusal → books come off, SnackBar. The one-book menu `addItem` goes through the same `addItems`.
- **Out of scope**: dark mode not designed; Android not ported; replacing the current screen is a later call once the v2 is judged.
- **First cut already on this branch** (design session, before the Figma second pass): routing, section, tabs, Présentation, sheet without search, batch write + 2 tests. Still to do against the maquette: remove the tab bar, swap the list-end card for the pinned button, add the search, open friends' étagères on v2.

## Acceptance criteria

- Inventaire with at least one étagère → « Étagères (v2) » below the carousel, one row per étagère with « N livres »; tapping a row opens the v2 screen; tapping a carousel card still opens the current screen.
- V2 screen of my étagère → its name inline in the nav bar, the pencil, the tabs « Livres • N » | « Présentation »; no tab bar at the bottom.
- « Livres » → the étagère's books, newest first, in an inset grouped list; tapping one opens its Fiche livre; swiping one left takes it off the étagère and « Livres • N » drops by one.
- « Livres » on my étagère → « Ajouter des livres » pinned at the bottom; « Présentation » → no button.
- Empty étagère → « Cette étagère est vide » and the pinned button still there.
- « Présentation » → description, Visible par, Créée le; « Modifiée le » only on an étagère edited after its creation; no description → « Cette étagère n'a pas de description ».
- « Ajouter des livres » → sheet titled « Ajouter des livres », `xmark` at the left, search field « Titre ou auteur·ice », my books not on the étagère, none ticked, button « Ajouter 0 livre » disabled.
- Ticking two rows → « Ajouter 2 livres » enabled; tapping a ticked row unticks it.
- Typing an author's name → only their books; a book ticked before stays ticked when the search is cleared, and is counted in the button meanwhile.
- Typing a word no book matches → « Aucun de vos livres ne correspond à « <mot> » ».
- « Ajouter 2 livres » → sheet closes, both books on the étagère at once, « Livres • N » up by two, still there after relaunch.
- Every book already on the étagère → the sheet says « Tous vos livres sont déjà sur cette étagère ».
- `xmark` → sheet closes, nothing added.
- Pencil → « Supprimer l'étagère » → confirm → the v2 screen pops back to the Inventaire (no blank screen).
- Friend's profile → tapping one of their étagères opens the v2 screen: same tabs, no pencil, no swipe, no « Ajouter des livres ».
- `ShelfModelAddItemsTests` pass: one call with only the books not yet on the étagère; refusal takes them off.

## Implementation

## Review

## Verification

## Feedback
