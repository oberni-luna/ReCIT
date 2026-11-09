---
issue: 100
status: to-test
wiki: [[features/0087-book-creation-from-search]], [[features/0043-android-create-a-missing-book]], [[features/0052-android-cover-zoom-edition-editing-context-menu]], [[features/0041-android-catches-up-with-ios]]
note: Rattrapage iOS 1.10.0 (feature 0087). Android opens Nouveau livre only from the scanner; NewBookDraft.isbn is non-null and always sent.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0087](../wiki/features/0087-book-creation-from-search.md).

- **Entry.** Android's Recherche has no « Sur inventaire.io » header: inventaire.io's absence is the « Aucun résultat » `EmptyState` of the remote results (`ui/search/SearchContent.kt`, `RemoteSearchState.Sign.NoResult`). It gains the action « Ajouter ce livre », whatever the local section shows above. Results found on inventaire.io → no button. Not on a failure (that one keeps « Réessayer »).
- **Presentation: a full-height overlay above the tabs** (Olivier's pick), like the transaction request form, holding `CreateBookScreen`. Closing keeps the draft; publishing closes it and pushes `Destination.Book(BookAnchor.Edition(uri))` on Recherche's stack.
- **Origin type.** `NewBookOrigin` = `Scan(isbn)` | `Search(query)`, as iOS: decides the work search's initial query (empty after a scan or an ISBN query, the query otherwise), whether the ISBN is editable, the initial ISBN (`IsbnQuery.isbn(query)`), the blank draft, and the drafts' key.
- **Drafts** in memory, keyed by origin, through one shared type used by `ScanViewModel` (as `Scan(isbn)`) and by Recherche (as `Search(query)`), held while Recherche lives (its tab-root scope). Same query → reopens the draft; another query → blank. Nothing on disk.
- **Text query**: the work search opens pre-filled with the query (`DebouncedSearch.setQuery`) and its own sentence « Cherchez le titre ou l'auteur·ice : si l'œuvre est déjà sur inventaire.io, il ne restera presque rien à saisir. » **ISBN query**: the work search opens empty with the ISBN sentence, and the edition's ISBN holds the 13 digits.
- **Editable ISBN** (from Recherche only): in the edition form's cover section a field « ISBN », placeholder « Facultatif », number keyboard. A wrong check digit shows « Cet ISBN n'est pas valide. Vérifiez ses chiffres. » once the field loses focus or 13 digits are in, and « Publier » stays disabled; empty or valid → « Publier » depends on the rest of the form. Same rule on « Œuvre déjà connue ». From the scanner the ISBN stays read-only and never blocks publishing.
- **Optional ISBN.** `NewBookDraft.isbn` editable; a `checkedIsbn` (13 digits when the check digit is right, ISBN-10 converted) built on `IsbnQuery`'s validator, empty counting as valid; `ResolveRequestBuilder` leaves `wdt:P212` out when empty.
- **Language lookup** runs on a valid `checkedIsbn` and follows it when it changes (no longer one-shot in init); cleared when the ISBN stops being valid.
- **Publishing** as after a scan: edition created, added to my Inventaire with the same defaults. `CreateBookSession`'s callback stops depending on `ScannedBook`; the scanner maps the result to its bilan as today.
- **Scanner unchanged**: ISBN read-only, same sentence, same bilan count.
- Strings French only.
- Out of scope: adding an edition to a work found in the results, a book created without adding it to the Inventaire, drafts on disk, cover search by ISBN (Android has none).

## Acceptance criteria

- Recherche, a title inventaire.io doesn't know: « Aucun résultat » with « Ajouter ce livre »; a query with inventaire.io results: no button.
- « Ajouter ce livre » on a text query: full-height « Nouveau livre » above the tabs, work search pre-filled with the query and the no-ISBN sentence.
- On an unknown ISBN query: the work search opens empty with the ISBN sentence; the edition form's ISBN field holds the 13 digits.
- Edition form from Recherche: ISBN field « Facultatif »; `9782070360025` then leaving the field → « Cet ISBN n'est pas valide. Vérifiez ses chiffres. » and « Publier » disabled; field emptied → « Publier » enabled if the rest is filled.
- Publishing without ISBN: the resolve request has no `wdt:P212` (unit test); the book is in my Inventaire; the overlay closes and Recherche shows its Fiche livre.
- Closing the overlay, then « Ajouter ce livre » on the same query: the draft is back; on another query: blank.
- Valid ISBN-10 typed: sent as 13 digits (unit test).
- Scanner, unknown barcode → « Nouveau livre »: ISBN read-only, publishing counts in the bilan, as before.
- Unit tests: origin rules, drafts by origin, check-digit validity (empty valid), publishability with editable vs scanned ISBN, resolve without P212.

## Implementation

- `data/creation/NewBookOrigin.kt`: sealed `Scan(isbn)` | `Search(query)` — `isbn` (via `IsbnQuery.isbn(query)`), `isIsbnEditable`, `workQuery` (trimmed query; empty after a scan or an ISBN query), `blankDraft`; the origin is the drafts' key.
- `data/creation/NewBookDrafts.kt`: in-memory `draft(origin)` / `remember(draft, origin)` / `forget(origin)`, used by `ScanViewModel` (`Scan(code)`) and `SearchViewModel` (`Search(query)`, tab-root lifetime).
- `NewBookDraft`: `checkedIsbn`, `isIsbnValid` (blank or valid), `normalizedIsbn` prefers `checkedIsbn` (ISBN-10 → 13), `isPublishable(isIsbnEditable)`. `ResolveRequestBuilder` omits `wdt:P212` when empty.
- `CreateBookSession(origin)` → `onCreated(editionUri, draft)`; the scanner builds its `ScannedBook` (`code = origin.isbn`), bilan unchanged. `CreateBookState.origin` / `canPublish` drive both « Publier » bars. Init `workSearch.setQuery(origin.workQuery)`. Language lookup follows `checkedIsbn` (`distinctUntilChanged` + `collectLatest`), null when invalid. `setIsbn` only when editable.
- `ui/createbook/CreateBookIsbnField.kt` in an optional `editableIsbn` slot of `EditionCoverSection` (scanner and « Modifier l'édition » unchanged): « ISBN », placeholder « Facultatif », number keyboard, error after focus loss or at 13 digits; tags `e2e.createBook.isbnField`, `e2e.createBook.isbnError`. Work-search sentence without ISBN: `create_book_search_empty_message_no_isbn`.
- `ui/createbook/CreateBookDialog.kt`: full-screen `Dialog` (no dismiss on back or outside tap) holding `CreateBookScreen` unchanged — chosen over a bottom sheet so a swipe cannot close it mid-publication; same kind of dialog as `ListScanScreen`.
- Recherche: `SearchContent` NoResult `EmptyState` action « Ajouter ce livre » → `onAddBook(query)` (also shown when a people-only search finds nothing, as iOS); `SearchViewModel.openCreation(query)`; on success forget the draft, close, `createdEditionUri` consumed once by `SearchScreen`, which pushes `Destination.Book(BookAnchor.Edition(uri))`. Closing keeps the draft. `groupedCell` untouched.
- Strings (`strings_create_book.xml`): `create_book_search_add_book`, `create_book_search_empty_message_no_isbn`, `create_book_isbn_placeholder`, `create_book_isbn_invalid`.
- Tests: `NewBookOriginTest` (4), `NewBookDraftsTest` (4), `NewBookDraftTest` (+3), `ResolveRequestBuilderTest` (+2). Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest` ✅ 0 failures.
- Not done: no test tag on « Ajouter ce livre » (`EmptyState` has no slot).
- Runtime not run: no inventaire.io credentials; nothing published. Status-bar icon colour and back handling inside the dialog unseen.

## Review

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
