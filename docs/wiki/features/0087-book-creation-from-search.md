# Nouveau livre from Recherche, with an optional ISBN

Shipped on 2026-11-06, iOS only (issue #16). « Nouveau livre » ([0047](0047-new-book-work-first.md)) opened only
from the Scanner, on a barcode inventaire.io did not know. Recherche can find nothing just as well, and it is the same
missing book. Now the absence of « Sur inventaire.io » opens the same flow on the query, and the ISBN, which no barcode
gave, becomes a field the reader may leave empty.

## What it does

- Recherche, a query inventaire.io finds nothing for: the « Sur inventaire.io » absence carries « Ajouter ce livre »
  (« Add this book »). It shows whether or not « Mes livres » or « Chez mes amis » found something above it. A query
  with results on inventaire.io shows no such button: a work found calls for adding an edition to it, which is
  another task.
- A text query: the « Nouveau livre » sheet opens on the work search, pre-filled with the query.
- A query that is an ISBN: the work search opens empty, with its ISBN sentence, and the edition form's ISBN field
  holds that ISBN as thirteen digits.
- A text query has no ISBN to say back, so the work search opens on its own sentence: « Cherchez le titre ou
  l'auteur·ice : si l'œuvre est déjà sur inventaire.io, il ne restera presque rien à saisir. » The screens of the
  flow are still on « vous », and the new strings follow them.
- In the edition form opened from Recherche, the cover row's ISBN is a field: label « ISBN », placeholder
  « Facultatif », number pad. A wrong check digit (`9782070360025`) shows « Cet ISBN n'est pas valide. Vérifiez ses
  chiffres. » under the row, once the reader leaves the field or the thirteen digits are in, and « Publier » stays
  disabled. Empty or valid, « Publier » depends on the rest of the form only. The same rule holds on « Œuvre déjà
  connue ».
- **The ISBN is optional.** inventaire.io's `POST /api/entities/resolve` validates an ISBN only when one is given,
  and resolves an edition without one. An edition without an ISBN is an ordinary edition, which the app already shows
  as « Sans ISBN » ([0051](0051-edition-duplicates.md)). Empty, the request carries no `wdt:P212`.
- A valid ISBN, typed or pre-filled, gives the edition its language and the cover search its ISBN, as a scan does.
  Both wait for a valid check digit, and follow the field when it changes.
- « Publier » does what it does after a scan: the edition is created and added to my Inventaire, with the same
  defaults. The sheet closes and Recherche pushes the new edition's Fiche livre. The same query then lists the book
  under « Mes livres »; « Sur inventaire.io » may lag behind, the server's search index not being instant.
- A sheet closed without publishing keeps its draft in memory while Recherche lives, tied to the query: « Ajouter ce
  livre » on the same query reopens it, another query starts blank. Nothing is written to disk. It is the scanner's
  rule for drafts by ISBN ([0020](0020-creating-a-book-that-inventaire-lacks.md)), which now goes through the same
  type.
- The Scanner's « Nouveau livre » is unchanged: the ISBN read-only, the same opening sentence.

## Technical surface

- `Model/Creation/NewBookOrigin.swift`: `.scan(isbn:)` or `.search(query:)`. Where the flow was opened from decides
  what it opens on (`workQuery`, empty after a scan or an ISBN query), whether the ISBN is typed (`isISBNEditable`),
  the ISBN it starts with (`isbn`, through `IsbnQuery.isbn(in:)`) and the `blankDraft`. It is also the identity of a
  draft and of the sheet (`Identifiable`).
- `Model/Creation/NewBookDrafts.swift`: drafts in memory, keyed by origin. `BatchScanViewModel` keeps its drafts by
  ISBN through it, as `.scan(isbn:)`; `SearchTabView` keeps its own, as `.search(query:)`.
- `NewBookDraft.isbn` is a `var`. `checkedISBN` is the thirteen digits once the check digit is right, an ISBN-10
  included; `normalizedISBN` prefers it, so a valid ISBN-10 now goes out as an ISBN-13. `isISBNValid` is true for an
  empty field or a right check digit, and `isPublishable(isISBNEditable:)` adds it to `isPublishable` only when the
  ISBN is typed, so a scanned ISBN never blocks publishing. `NewEditionView` and `WorkMatchView` both read it.
- `ResolveRequestBuilder` leaves `wdt:P212` out when the ISBN is empty.
- `NewBookFlowView` takes `origin:`. The language lookup is `.task(id: draft.checkedISBN)`, cleared when the ISBN stops
  being valid; the cover search (`BookCoverURLView`) gets `checkedISBN`. For the Scanner this means both run only for
  a valid check digit, which a barcode almost always has.
- `Features/CreateBook/CreateBookISBNField.swift`: the field and its error, identifiers `e2e.createBook.isbnField`
  and `e2e.createBook.isbnError`. `CreateBookCoverRow` shows it through an `.editableISBN(_:isValid:)` modifier, so
  its initializer and the Scanner's call site stay as they were.
- `WorkSearchView` takes an optional `isbn` (`nil` gives the no-ISBN sentence) and a `query:`. `EditEditionFlowView`
  passes the edition's ISBN as it is.
- `SearchRemoteSection`, state `.noResult`: the action on its `EmptyStateView`, identifier
  `e2e.searchNoResult.addBook`. `EmptyStateView.Action` takes an optional identifier, applied only when given.
- The button calls the environment action `\.openNewBook` (`OpenNewBookAction`, `EnvironmentValues+OpenNewBook`,
  built like `showBibliographicDataHelp`), not a closure. A closure would have to pass through `SearchContent.swift`,
  which the SwiftLint baseline pins at its exact line count for `file_length`: one more line breaks the build.
- `SearchTabView` sets the action, presents the sheet on its `NewBookOrigin`, holds the drafts, and on dismiss pushes
  `NavigationDestination.book(anchor: .edition(uri:))` for the edition just published.
- Strings, French and English: `inventory.search.results.empty.add_book`, `create_book.isbn.placeholder`,
  `create_book.isbn.invalid`, `create_book.search.empty.no_isbn`.
- Tests: `NewBookOriginTests`, `NewBookDraftsTests`, and new cases in `NewBookDraftTests` (check digit, ISBN-10 sent
  as 13 digits, a wrong typed ISBN blocks publishing and a scanned one does not) and `ResolveRequestBuilderTests` (no
  `isbn` key when empty).

## Not done / owed

- Seen on the simulator (iPhone 17, iOS 26.4): the absence with « Ajouter ce livre », the sheet with the work search
  pre-filled, « Créer l'œuvre » to « Nouvelle œuvre ». The ISBN field was never reached, and nothing was published.
  Every other on-screen criterion is owed, publishing on a test account included. e2e was not run.
- The error shows on focus loss or at thirteen digits. `X` is accepted when pasted, but the number pad cannot type it.
- `e2e.searchNoResult`, set on the whole empty state, may hide the button's own identifier from XCUITest.
- The `type_contents_order` entries for `WorkSearchView` in the SwiftLint baseline are stale.
- Out of scope: Android, adding an edition to a work found in the results, creating a book without adding it to the
  Inventaire, drafts on disk.
