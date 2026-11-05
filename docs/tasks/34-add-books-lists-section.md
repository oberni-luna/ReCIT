---
issue: 34
status: todo
wiki: [[book-and-editions]], [[lists]], [[design-system/figma-library]]
note: Figma — section 744:2382 (file S7IvC6GvlcUFe5IgbtvQq6), N1 944:7954, N2 944:8280, spec 945:8188
created: 2026-11-05
---

## Context / Decisions

> Fiche livre : section « Dans les listes » — les listes d'œuvres qui contiennent l'œuvre de l'édition.
> Toucher une liste l'ouvre, défilée jusqu'au livre, qui s'éclaire un instant.

- **What**: the Fiche livre (`BookDetailView`) gets a section « Dans les listes » naming every list that holds the book.
  A tap opens the Liste, scrolled to that book, highlighted once.
- **Mockups**: Figma section `Fiche livre · Données bibliographiques` (`744:2382`), second row.
  - `N1 · Fiche livre · Dans les listes` (`944:7954`) — the section.
  - `N2 · Liste ouverte sur le livre, éclairé` (`944:8280`) — the arrival.
  - `Spec · Fiche livre · Dans les listes` (`945:8188`).
  - **Divergence from the mockup**: N1 shows my lists first; the grill decided one mixed order (below).
- **Place**: after « Dans mon inventaire » (`myCopySection`), before « Données bibliographiques ».
  Header « Dans les listes », a section like « Dans la communauté ».
- **Which lists**: lists of works only (`EntityListType` work) whose elements hold one of the edition's work uris
  (`Edition.workUris`).
  - Mine and my friends' lists: both are already in the store (feature 0068). Nothing new server-side.
  - Lists of authors excluded.
  - No list holds the book → no section at all.
- **Reactive**: `@Query` on `EntityListItem` by uri (ADR 0001). An add or remove made elsewhere shows without reload.
- **Row**: `ListRowView` as in the Listes tab — covers fan, count line, name, explanation.
  A friend's list passes its owner: picture and name before the count (« Rémi • 9 œuvres »).
- **Order**: all lists mixed, most recently updated first (`updated`, else `created`). Not mine-then-network.
- **How many**: all of them. No « Voir les N listes ».
- **No « Ajouter à une liste » row**: the « … » menu already does it (feature 0016).
- **Recueil**: two of its works in one list → the list shows once, opened on the first of them in list order.
- **Navigation**:
  - A tap pushes `NavigationDestination.entityList` on the current tab's path.
    The case gains the uri to focus (`focusURI: String?`, nil everywhere else); its `id` includes it.
  - The list opens on the Livres tab.
    The cover flow starts on its first book, then scrolls to the focused uri (~0.4 s spring).
  - On arrival: the cover flow's selection haptic, and a `foreground/tinted` halo around the cover that fades in 1.2 s.
    Once, on arrival only. A swipe cuts it short.
  - Reduce Motion: no scroll, the list opens on the book, the halo fades without movement.
  - VoiceOver: focus on the book's title.
  - A friend's list opens read-only, as from the Listes tab (existing `isMine`).
  - Back returns to the Fiche livre at its scroll position.
  - From a list → its book → the same list again: pushed a second time, highlighted. No path surgery.
- **Scope**: iOS only. Android follows in a later catch-up batch.

## Acceptance criteria

- A book whose work is in 2 of my lists and 1 friend's list → « Dans les listes » shows 3 rows,
  between « Dans mon inventaire » and « Données bibliographiques ».
- Rows are ordered by last update, most recent first, mine and friends' mixed.
- The friend's row shows the friend's picture and name before the count.
- A book in no list → no « Dans les listes » header, no empty card.
- A book only in a list of authors → no section.
- A recueil with two works in one list → that list shows once.
- Adding the book to a list from the « … » menu → the new row appears without leaving the screen.
- Tap a row → the Liste opens on Livres, the cover flow scrolls from its first book to this one and stops on it.
- On arrival the cover gets a tinted halo that fades within ~1.2 s, with one selection haptic.
- Reduce Motion on → the Liste opens directly on the book, no scroll.
- Tap a friend's list → read-only: no add bar, no « Retirer de la liste ».
- Back from the Liste → the Fiche livre, same scroll position.
- Opening a list from the Listes tab is unchanged: first book selected, no halo.

## Implementation

## Review

## Verification

## Feedback
