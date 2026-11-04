# Names, titles and descriptions in the phone's language

Shipped on 2026-10-30. No PRD and no issues: one slice, decided in a grill-me session the user validated.

## What it does

On a phone set to English, Victor Hugo's screen said « romancier, poète, dramaturge, dessinateur et politicien
français (1802–1885) » under an English interface. Every request to inventaire.io carried `lang=fr`, hard-coded in a
dozen places, and `Author` and `Work` read `descriptions["fr"] ?? descriptions["en"]`.

Everything inventaire.io is asked for now comes **in the phone's language**: an author's and a work's description,
the names of authors and the titles of works (« The Hunchback of Notre-Dame » on a phone in English), genres, the
Wikipedia summary, search results, publisher and collection names, the labels of the book-creation flows. A phone in
French sees no change.

## Technical surface

- **`ContentLanguage`** (`Model/Utils/`) — `preferred` is the language code of `Locale.preferredLanguages.first`
  (`en` for `en-FR`), `"fr"` when there is none. `nonisolated`, since it is the default value of parameters.
- **Every `lang=fr`** of `EntityModel` (`fetchEntities`, `nameRelatives`), `WorkEditionResolver`,
  `GenreEnrichmentModel`, `EntityCreationModel`, `EditionPagesLoader` and `SearchModel` now reads
  `ContentLanguage.preferred`. `WorkEditionResolver.preferredLang` is gone, so the edition opened for a work is now
  the best one in the phone's language.
- **`EntityLabel`** — the order is the phone's language, then `fr`, `en`, `mul`, the original language, the
  smallest code. `resolve` / `language(of:)` take `preferredLanguage`, defaulting to `ContentLanguage.preferred`.
- **`EntityDescription`** (`Model/Books/`) — the same for descriptions: the phone's language, `fr`, `en`, then the
  smallest code. `Author` and `Work` read it in `init(entityDTO:)` and `update(entityDTO:)`.
- **`EntityModel.fetchExtract`** — `summaries` is asked with `langs=<phone>|fr`; for each language in that order,
  the summary property first, then `<lang>wiki` through `wp-extract`.
- **`ResolveRequestBuilder.defaultLabelLanguage`** and **`WorkEditionPicker`**'s default language filter read
  `ContentLanguage.preferred` rather than `Locale.current`. `EntityEdit` takes `preferredLanguage` too, so the label
  shown — and the one a rename replaces — is the phone's.

## Notable decisions

- **`Locale.preferredLanguages`, not `Locale.current`.** The app is localised in English and French only; on a phone
  in Japanese `Locale.current` answers with English, the language the app fell back to, where Wikidata has a Japanese
  name.
- **Titles follow, not only descriptions.** `lang=` filters labels and descriptions together and returns one
  language per entity, so keeping titles in French would have taken a second call. The user chose one language and
  one call.
- **No migration.** What is in the store stays in the language it was fetched in until the entity is fetched again
  — opening an author's screen refreshes it, so Victor Hugo turns English the next time he is opened. A stored
  Wikipedia summary is never fetched again, so it keeps its language; `WpExtract` carries none.
- **The server's fallback is shown.** Asked for a language it has no description in, `by-uris` answers with
  another (Dutch, for `wd:Q3205794` asked in Japanese). That description comes after `fr` and `en`, but it is shown.
- **The auto-sort prompt is unchanged.** It is written in French and asks for French étagère names; the genres it
  reads may now be in English.

## Not done, not verified

- Built and unit suite green (1069 passed). Not seen on a simulator; e2e not run.
- **Android** (`Recit_Android/`) still sends `lang=fr` in `EntityRepository`, `SearchRepository` and
  `EntityCreationRepository`.
