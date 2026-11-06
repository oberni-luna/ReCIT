---
issue: 16
status: to-test
wiki: [[search]], [[book-and-editions]], [[features/0047-new-book-work-first]], [[features/0020-creating-a-book-that-inventaire-lacks]]
note: migrated from docs/issues/0097-the-second-door-from-search.md (frame C6 of PRD 0015, out of v1 scope)
created: 2026-11-06
---

## Context / Decisions

> Le scanner n'est pas le seul endroit où un livre manque. La recherche unifiée aussi peut ne rien
> trouver, ni chez moi, ni chez mes amis, ni sur inventaire.io — et c'est le même livre absent.
>
> - L'absence de la section « Sur inventaire.io » gagne une action « Ajouter ce livre », posée sur le
>   composant d'absence de l'app.
> - Sans code-barres, l'ISBN n'est plus connu : il devient un **champ à saisir**, avec sa validation
>   de clé de contrôle. C'est le seul écart avec le parcours du scan ; tout le reste du formulaire est
>   celui de la v1.
>
> Pourquoi HITL : reste à trancher si l'ISBN est obligatoire.
> — original issue body, `docs/issues/0097-the-second-door-from-search.md`

iOS only. The **Nouveau livre** flow of 0047 (`NewBookFlowView`: work search → edition form,
or new work → edition form), opened from Recherche instead of the Scanner.

- **Blocker landed.** Issue 0096 (failure banner + drafts kept by ISBN) shipped in `dff8b1d`.
- **The ISBN is optional.** inventaire.io's `POST /api/entities/resolve` validates an ISBN only
  when one is given (`server/controllers/entities/lib/resolver/sanitize_entry.ts` on Codeberg:
  `if (rawIsbn != null)`), and `resolveEdition` runs without one. An edition without ISBN is
  an ordinary edition; the app already shows them as « Sans ISBN » (0051). The issue's premise
  that an edition needs an ISBN is wrong.
- **Entry point: only the « Sur inventaire.io » absence.** `SearchRemoteSection`, state
  `.noResult`, gets an action on its `EmptyStateView`. It shows whether or not « Mes livres » or
  « Chez mes amis » found something. No row under non-empty results: a work found means the
  right gesture is adding an edition to that work, which is another task.
- **The ISBN field lives in the edition form's cover row.** `CreateBookCoverRow` shows the
  scanned ISBN read-only today. Opened from Recherche, it becomes a `TextField` (number pad,
  `X` accepted). A wrong check digit shows an error under the row and disables « Publier ».
  Once valid, the edition language is inferred from it as for a scan
  (`EntityCreationModel.editionLanguage(isbn:)`). Empty → published without ISBN.
- **What the flow opens on.**
  - Query is a text: the work search opens pre-filled with it.
  - Query is an ISBN (`IsbnQuery.isbn(in:)`): the ISBN field is pre-filled, the work search
    opens empty with its current ISBN sentence.
- **After « Publier »: same as the scan, then the Fiche livre.** The edition is created and added
  to my inventory (same button, same defaults: `.inventorying`, visible to friends). The sheet
  closes, and Recherche pushes the new edition's Fiche livre. For the same query the book then
  shows under « Mes livres »; « Sur inventaire.io » may lag, since the server's search index is
  not instant. No "create without adding" option.
- **Draft.** A sheet closed without publishing keeps its draft in memory while Recherche lives,
  tied to the query: « Ajouter ce livre » on the same query reopens it; another query starts
  blank. Nothing on disk. Same rule as the scanner's drafts by ISBN (0096).
- **Model change implied.** `NewBookDraft.isbn` stops being a camera-only `let`; an empty ISBN
  must flow through `normalizedISBN`, the cover search (`CoverURLView`) and `resolve` without
  sending an `isbn` key. Check-digit validation reuses `IsbnNormalization` / `IsbnQuery`.
- **Copy** (screens are still on « vous », new strings follow them):

  | where | fr | en |
  |---|---|---|
  | action on the absence | Ajouter ce livre | Add this book |
  | ISBN field label · placeholder | ISBN · Facultatif | ISBN · Optional |
  | wrong check digit, under the row | Cet ISBN n'est pas valide. Vérifiez ses chiffres. | This ISBN is not valid. Check its digits. |
  | work search at rest, no ISBN | Cherchez le titre ou l'auteur·ice : si l'œuvre est déjà sur inventaire.io, il ne restera presque rien à saisir. | Search for its title or its author: if the work is already on inventaire.io, there will be almost nothing left to type. |

  Sheet title stays « Nouveau livre ».
- **Out of scope:** Android (next « Android catches up » batch), adding an edition to a work
  found in results, creating without adding to the inventory, drafts on disk.
- **Glossary:** `Nouveau livre` flow now reads « Scanner ou Recherche → œuvre → édition »
  (approved in the grill, committed on this branch).

## Acceptance criteria

- [ ] Recherche, a query inventaire.io finds nothing for → the « Sur inventaire.io » absence shows « Ajouter ce livre » / "Add this book".
- [ ] A query with results on inventaire.io → no « Ajouter ce livre ».
- [ ] « Ajouter ce livre » after a text query → « Nouveau livre » sheet, work search pre-filled with the query.
- [ ] « Ajouter ce livre » after an ISBN query nobody knows → work search empty with the ISBN sentence; the edition form's ISBN field holds that ISBN.
- [ ] Edition form opened from Recherche → ISBN field editable, placeholder « Facultatif ».
- [ ] ISBN with a wrong check digit (e.g. `9782070360025`) → « Cet ISBN n'est pas valide. Vérifiez ses chiffres. » under the row, « Publier » disabled.
- [ ] Valid ISBN or empty field → « Publier » enabled (given the form's other required fields).
- [ ] Empty ISBN → the `resolve` request carries no `isbn` key (unit test on the request builder).
- [ ] Publish succeeds → sheet closes, the new edition's Fiche livre is pushed in Recherche, and the same query lists the book under « Mes livres ».
- [ ] Close the sheet after typing a title, tap « Ajouter ce livre » again on the same query → the title is still there; on another query → blank form.
- [ ] Scanner's « Nouveau livre » unchanged: ISBN read-only, same opening sentence.
- [ ] New strings in French and English.

## Implementation

- New `Model/Creation/NewBookOrigin.swift` (`.scan(isbn:)` / `.search(query:)`: `isbn` through `IsbnQuery.isbn(in:)`, `isISBNEditable`, `workQuery` empty for an ISBN query, `blankDraft`) and `Model/Creation/NewBookDrafts.swift` (in-memory drafts keyed by origin; the scanner's drafts-by-ISBN use it too).
- New `Features/CreateBook/CreateBookISBNField.swift` (number pad, « ISBN » + « Facultatif », error in `.foregroundError`), `OpenNewBookAction.swift` + `EnvironmentValues+OpenNewBook.swift` (`\.openNewBook`, built like `showBibliographicDataHelp`).
- `NewBookDraft`: `isbn` is a `var`; `checkedISBN`, `isISBNValid` (empty or right check digit); `normalizedISBN` prefers `checkedISBN` (ISBN-10 sent as ISBN-13). `ResolveRequestBuilder`: no `wdt:P212` when the ISBN is empty.
- `NewBookFlowView` takes `origin:`; work search pre-filled from `origin.workQuery`; language lookup `.task(id: draft.checkedISBN)`; cover search on `checkedISBN`. `NewEditionView`: « Publier » needs `isISBNValid` when the ISBN is editable. `CreateBookCoverRow`: editable field when opened from Recherche. `WorkSearchView`: `query:` init, no-ISBN opening sentence.
- `SearchRemoteSection`: `.noResult` gets « Ajouter ce livre » (`e2e.searchNoResult.addBook`) → `openNewBook(.search(query:))`. `SearchTabView` holds the sheet, the drafts and the created edition, and pushes its Fiche livre on dismiss. `EmptyStateView.Action` takes an optional identifier. `SearchContent.swift` untouched: it sits in the baseline for `file_length` at its exact count, hence the environment action instead of a closure.
- Scanner: passes `.scan(isbn:)`; ISBN read-only, `isPublishable` unchanged. Language lookup and cover search now run only for a valid check digit.
- Strings fr + en: `create_book.isbn.invalid`, `create_book.isbn.placeholder`, `create_book.search.empty.no_isbn`, `inventory.search.results.empty.add_book`.
- Notes: the error shows on focus loss or at 13 digits; `X` accepted when pasted, not typeable on the number pad; the ISBN pre-fill is the normalized 13 digits; `e2e.searchNoResult` on the whole empty state may hide the button's own identifier; WorkSearchView's `type_contents_order` baseline entries are stale.
- Proof: build ✅ · tests ✅ 67/67 (NewBookDraftTests, NewBookDraftsTests, NewBookOriginTests, ResolveRequestBuilderTests, EntityCreationModelTests, BatchScanViewModelTests; 10 new). Nothing sent to inventaire.io.

## Review

## Verification

manual validation — not run by agent. Owed: every on-screen criterion, publishing included (never on a real account by an agent).

## Feedback
