---
issue: 23
status: todo
wiki: [[features/0057-edit-works-and-authors]], [[features/0054-forms-on-the-book-screens-dark-cards]], [[features/0050-every-bibliographic-datum]], [[features/0052-android-cover-zoom-edition-editing-context-menu]]
note: split from #20; sprint Android 1.3.0; independent of #21/#22
created: 2026-11-04
---

## Context / Decisions

> Full « Modifier l'œuvre » and « Modifier l'auteur·ice », dark cards. Split from #20 on 2026-11-04.

- **Goal:** Android work and author editing at iOS 0057 parity, form cards at iOS 0054.
- **Branch:** coded on `sprint/android-1-3-0` after #21 and #22, one commit.
- **Scope (decided: full parity):**
  - « Modifier l'œuvre »: titles per language + « Ajouter le titre dans une autre langue », type (6), form (31), original language, first-publication date, authors and every role (Ont aussi fait cette œuvre, Bande dessinée roles), Série + rank, Genre et sujet, Liens avec d'autres œuvres, 20 catalogues, Sur le web, « À ne pas confondre avec ».
  - « Modifier l'auteur·ice »: names per language, pseudonyms, writing languages, dates, movement, influenced by, 29 catalogues, 11 link kinds.
  - Value kinds `.choice`, `.text`, `.ordinal`, `.anyEntity` (multi-type search) added.
  - Catalogues per entity type, as data tables, on the `EditionProperty` model.
- **Saving:** one « Enregistrer » per entity screen, saved alone through the existing `update-claim` / `update-label` (`EntityCreationRepository`), server-first, not optimistic. Failure → banner; a retry sends only what has not landed. The work is no longer saved with the edition.
- **Leaving unsaved:** « Quitter sans enregistrer ? », same pattern as `ui/sort/SortSurfaceScreen.kt`.
- **Entry points:** the author screen opens from the edition's and the work's role lists.
- **After save:** « Édition de » and the book screen refresh.
- **Only inventaire.io entities are editable.** No Wikidata (0070) in this version.
- **Dark cards (0054):** tokens `backgroundForm` (gray/800 ground), `backgroundFormCell` (black 40 % veil), `backgroundShade` in `RecitColors.kt`; the book screen uses the same two. Light unchanged.
- **Wording:** labels copied from iOS 0057 (`EditionPropertyLabels` style).

## Acceptance criteria

- [ ] Edition form → work row → « Modifier l'œuvre » shows every section listed above, prefilled from inventaire.io
- [ ] Add a title in another language, change the type → « Enregistrer » enabled; save sends one `update-claim` / `update-label` per change
- [ ] A refused call → banner; retry sends only the remaining changes
- [ ] Back with unsaved changes → « Quitter sans enregistrer ? »; « Quitter » discards
- [ ] Tap an author in a role list → « Modifier l'auteur·ice » with names, pseudonyms, languages, dates, movement, influences, 29 catalogues, links
- [ ] A Wikidata work or person shows no edit entry
- [ ] After saving a work, « Édition de » and the book screen show the new values
- [ ] Dark mode: form cards are a 40 % black veil on a gray/800 ground; book screen same; light mode unchanged
- [ ] Unit tests: claim diff per value kind, catalogue tables per entity type, retry sends only the rest
