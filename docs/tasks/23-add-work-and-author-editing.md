---
issue: 23
status: to-test
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

## Implementation

- **Property model per entity type:** `WorkProperties.kt` (6 types, 31 forms, 20 catalogues), `HumanProperties.kt` (29 catalogues, 11 link kinds incl. LinkedIn), edition unchanged (22); `EditionPropertyCatalogue.kt`, `EditionPropertyChoice.kt`. A uri is always resolved in its entity type's table.
- **Value kinds:** `AnyEntity` (multi-type search), `Choice`, `Text`, `Ordinal` (rank sent as a string); search types series, genres, movements added.
- **`EntityEdit`:** labels per language + properties → one `update-claim` per changed claim, then one `update-label` per changed label; retry sends only what has not landed; an emptied label or a nameless entity cannot be saved.
- **Repository:** `EntityCreationRepository.editableEntity` / `saveEntity`, server-first, one step loop shared with `saveEdition`.
- **Screens:** `EditEntityPage`, `EditWorkForm`, `EditAuthorForm`, `EntityFormRows` in `ui/editedition`, pages over « Modifier l'édition », one per uri. Own « Enregistrer », failure banner, « Réessayer », « Quitter sans enregistrer ? ». A person opens from the work's authors and every list of names.
- **Work no longer saved with the edition:** renaming existing works and changing their authors removed from `EditionEdit` / `WorkEdit`; `EditWorkPage` only serves a work being created.
- **After save:** « Édition de » and the other open pages update; `EntityRepository.applyEntityEdit` reloads the work or person for the book screen; removed authors unlinked.
- **0054:** `backgroundForm`, `backgroundFormCell`, `backgroundShade` in `RecitColors.kt`, on every `FormSection` form. Android-only `backgroundBook` (form ground in dark, white in light) keeps the book screen's light mode unchanged.
- **Not ported:** Wikidata editing (a Wikidata work or person shows no edit entry); label languages limited to iOS's 27.
- **Proof:** `./gradlew assembleDebug :app:testDebugUnitTest` green, 596 tests (new: `EntityEditTest`, `EditionPropertyCatalogueTest`, `EntityCreationRepositoryEntityTest`). Never saved to inventaire.io for real, dark mode never looked at.

## Verification

manual validation — not run by agent
