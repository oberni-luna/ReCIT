---
issue: 97
status: todo
wiki: [[features/0079-the-lists-a-book-is-in]], [[features/0068-lists-in-my-network]], [[features/0077-android-catches-up-with-1-9-0]], [[features/0062-android-catches-up-with-1-7-0]]
note: Rattrapage iOS 1.10.0 (feature 0079). Friends' lists and elements are already in Room since 0077.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0079](../wiki/features/0079-the-lists-a-book-is-in.md), whole, arrival animation included (Olivier's pick).

- **Section « Dans les listes »** on the Fiche livre (`ui/book/BookScreen.kt`), between « Dans mon inventaire » and « Données bibliographiques ». One row per list of works holding one of the edition's works, drawn as the Lists tab's row (fanned covers, count, name, explanation); a friend's row starts its count line with their picture and name.
- **Whose.** Mine and my friends' (`creatorId`). A stranger's list in Room (profile opened) is left out; lists of authors are left out.
- **Order.** Mixed, most recently changed first (`updated ?: created`).
- **No list → no section**, no header, no empty card, no « Ajouter à une liste » row.
- **A recueil**: a list holding two of its works shows once and opens on the first of them in the list's order (lowest `ordinal`).
- **Data.** Reactive (ADR 0001): a Room query of the elements whose `uri` is one of `BookUiState.works` URIs, joined to their lists, plus the friends — an add or removal elsewhere updates the section. Nothing new goes to the server. No index or migration on `list_elements.uri` (volumes are small).
- **Pure rule, tested**: filter (mine/friends, works only), dedupe (focus = lowest ordinal), order — the iOS `BookListEntry.entries` as a Kotlin function with unit tests.
- **Opening.** `Destination.EntityList` gains `focusUri: String? = null`; a tap pushes it on the current tab, on its « Livres » page. A friend's list opens read-only, as from the Lists tab. Back returns to the Fiche livre at the same scroll position. The same list may be pushed twice; the stack is not inspected.
- **Arrival, as iOS.** The cover flow starts on the list's first book; ~300 ms later it scrolls in 0.4 s to the focused book (through `requestSelection`); once centred, its cover gets a halo in `foregroundTinted` (2 dp stroke 5 dp out + a 14 % 8 dp stroke 11 dp out) fading in over 1.2 s; one haptic on arrival; TalkBack focus moves to the book's title. Once per opening; a swipe or a touch elsewhere puts the halo out at once.
- **One haptic only.** The cover flow's page-change haptic must not also tick for the first selection on opening — on every list, as iOS.
- **Reduced motion** (system « Supprimer les animations », animator scale 0): the list opens directly on the book, the halo only fades.
- **Arrival state machine** (`waiting` → `arriving` → `highlighted` → `done`) pure and unit-tested, as iOS `ListArrivalFocus`.
- String « Dans les listes » (French only).

## Acceptance criteria

- A book whose work is in one of my lists and one friend's list: « Dans les listes » between « Dans mon inventaire » and « Données bibliographiques », two rows, the friend's showing their picture and name, the most recently updated first.
- A book in no list: no section, no header.
- A list of authors holding the book's author: not shown. A stranger's list (their profile opened before): not shown.
- Removing the work from my list elsewhere, then back to the book: the row is gone without reload.
- Tap my list's row: the list opens on « Livres », on its first book, then scrolls to the book, the halo fades in, one vibration.
- Swiping the cover flow right after: the halo goes out.
- With animations off in the system settings: the list opens directly on the book, halo fades in, no scroll.
- Tap a friend's list row: it opens read-only (no add bar, no remove), same arrival.
- Back: the Fiche livre at the same scroll position.
- Opening any list from the Lists tab: no vibration on opening.
- Unit tests: entries filter/dedupe/order; arrival state machine.
