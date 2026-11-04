# Creating a book inventaire.io lacks, on Android

Shipped on 2026-10-21, from PRD 0021 and issues 0118–0120, in an autopilot run, on top of the
`android-scan-sort` branch. It ports [0020](0020-creating-a-book-that-inventaire-lacks.md) from the
iOS app to the Android scanner of [0042](0042-android-scan-and-sort.md). The PRD and the issues were
scaffolding and were never committed.

The second door of iOS, creating a book from a search that finds nothing (issue 0097), does not
exist on iOS either, and is not here.

## What it does

- **The unknown row has an action.** « Cette édition n'existe pas sur inventaire.io » keeps its red
  caption, and gains a round button in the place of the « + ».
  - It carries the same « + » glyph, as on iOS. Only its label, « Créer ce livre sur inventaire.io »,
    tells it apart from the add.
  - The row still holds until acted on, and a different barcode still evicts it.
- **« Nouveau livre »** replaces the camera feed while it is up.
  - The camera is released, so the cover photograph can use it, and no barcode counts.
  - It shows the ISBN read off the barcode, not editable.
  - It shows « Langue, déduite de l'ISBN : … » once `GET /api/data/isbn` has answered, and nothing
    when it has not.
  - The public notice says the book joins an open, editable database.
  - It asks for « Titre de cette édition » and the author, and nothing else.
  - The cover slot is a dashed frame; a tap opens the camera app.
- **The author** is a row, not a text field. It opens a picker:
  - a search field, focused, that searches people (`/api/search`, `types=humans`) 300 ms after the
    last keystroke, from two characters;
  - « Déjà sur inventaire.io »: each result with its description, to tell namesakes apart;
  - « Créer « … » » underneath them all, and « Aucun auteur de ce nom… » when the search found none.
  - A chosen author is sent by uri; a created one by label.
- **Publishing** asks before it writes.
  - « Publier et ajouter à mes livres » first sends `POST /api/entities/resolve` with `create: false`,
    which writes nothing.
  - If that dry run recognises a work, « Ce livre est connu » shows it, read from the store after a
    refresh. Two answers: « Une édition de plus » (the default) or « Non, c'est un autre livre ».
    « Publier cette édition » publishes from there. The question is put once per draft.
  - Then the creation, with `create: true`, then `POST /api/items` with the scanner's defaults. Both
    are awaited.
  - The row turns to the confirmed state, the session counts the book, and the camera comes back.
- **A failure is said in the form**, above everything, in three cases:
  - an expired session: « Contribuer demande un compte »;
  - a refused entry: « inventaire.io a refusé ce livre », with no retry offered;
  - everything else: « La publication n'est pas passée », and the button reads « Réessayer ».
  - Each says first that nothing was created. « Garder le brouillon et revenir » appears only after a
    failure.
- **While a publication is in flight** the cross, the back gesture and « Ce livre est connu »'s back
  arrow do nothing.
- **Drafts are kept by ISBN** for the scanning session. Closing the form and coming back to the same
  barcode finds the title, the author, the photograph and the answer about the work. A draft that
  became a book is forgotten.

## Technical surface

- **`data/scan/`**: `BatchScanEvent.CreationFinished(book)`. It applies only from `NotFound` for the
  same code, lands in `Added`, and counts. The two iOS cases are in `BatchScanStateMachineTest`.
- **`data/creation/`**, pure but for the repository:
  - `NewBookDraft`, `EditionLanguage`, `ResolveRequestBuilder`, `CreateBookFailure`;
  - `EntityCreationRepository`: the ISBN's language through `publicApi`, the cover upload, the dry
    run and the creation through the session `api`. Only the creation throws.
- **`network/`**:
  - `dto/EntityResolveDtos.kt`: the resolve request and response, and `IsbnFactsDto`;
  - `ApiService.upload`: one file as `multipart/form-data`, decoded as a map. The server keys it by
    the form field's name, `cover`.
  - `AppContainer.creation` builds the repository.
- **`ui/createbook/`**:
  - `CreateBookSession`: the form's state as one `StateFlow`, and its actions. It is created by
    `ScanViewModel.openCreation()` in the view model's scope and dropped by `closeCreation()`.
  - `CreateBookScreen`: the form, the author picker and « Ce livre est connu », as three pages of one
    composable with one `BackHandler`.
  - `CoverPhoto`: the capture file, its `FileProvider` uri, and the reduction.
- **`ui/scan/`**:
  - `ScanViewModel` keeps `creation` and the drafts, and ignores barcodes while a form is up;
  - `ScanCameraScreen` draws the form in place of the feed;
  - `ScanResultRow` gains the creation button. Both round buttons now share `ScanRoundButton`.
- **Manifest**: a `FileProvider`, authority `${applicationId}.covers`, sharing `cache/covers/` only
  (`res/xml/cover_paths.xml`). No new permission and no new dependency.
- **Strings**: `strings_create_book.xml`, the French values of `create_book.*` and
  `scanner.action.create_book`.
- **Tests**: 275 JVM tests, all green. 23 are new:
  - the two machine cases;
  - `ResolveRequestBuilderTest`, against the encoded JSON where an omitted key matters;
  - `EntityResolveResponseTest`;
  - `CreateBookFailureTest`;
  - `EntityCreationRepositoryTest`, over MockWebServer: an interceptor redirects inventaire.io to it.

## Decisions worth knowing

- **The form is drawn by the camera's entry, not pushed on the flow's back stack.**
  - iOS poses a sheet on the camera, so that its navigation does not braid with the book screen's. A
    pushed entry would also have needed the scan view model's drafts and its `CreationFinished`,
    which live in another entry's store.
  - The three pages are a state of `CreateBookSession`, not destinations.
- **The session lives in `ScanViewModel`'s scope**, so a rotation keeps the form, its draft and a
  publication in flight. Leaving the scanner cancels it with the rest of the session.
- **The camera is released under the form.** iOS poses its sheet over the feed. Here the camera app
  needs the lens for the cover, and a barcode seen behind the form could evict the row the form is
  about.
- **The cover is taken by the camera app**, `ActivityResultContracts.TakePicture`, into the cache.
  - The photo picker takes over when no camera app answers, or the system refuses the intent. iOS
    falls back to the library only where there is no camera.
  - `ImageDecoder` turns the photograph upright from its EXIF orientation and scales its longest edge
    to 1600 px; it is written as JPEG 80, as on iOS. `android.media.ExifInterface` was avoided: lint
    flags it, and the fix it asks for is a new dependency.
- **Nothing is optimistic**, as on iOS: a public duplicate cannot be taken back from a phone.
- **Leaving is refused while a publication runs.** Closing cancels the session's coroutines, and a
  creation cut off between the server's answer and the item would leave the book on inventaire.io
  and not in the inventory.
- **On a failure from « Ce livre est connu », the form comes back** with its banner. iOS shows the
  failure on the form, under the pushed page. The draft keeps the answer, so « Réessayer » publishes
  straight away.
- **A missing user is « Contribuer demande un compte »**, the same sentence as a `401`.
- **The confirmed row shows the uploaded cover.** iOS passes none, so its row shows no image.

## Not done, or not verified

- **Never run.** The three commits build, and their unit tests pass. Lint shows no issue in the
  touched files; the 12 errors it reports are older, in other screens. No screen of the flow has been
  seen on a device or an emulator, signed in or not.
  - The camera app's round trip, the `FileProvider` grant and the photo picker fallback need a phone.
  - The keyboard over the form and the author picker, and TalkBack on the banner and the two choices,
    need eyes.
- **Nothing has been created on inventaire.io from Android.** A publication against the real server
  writes a public entity, so it waits for a deliberate test with a real unknown ISBN.
- **No test covers `CreateBookSession`, `CoverPhoto` or the screens.** They need the Android
  framework, Room or Compose UI tests, none of which the project has.
- **Not ported**:
  - the `e2e.createBook.*` accessibility identifiers, since Android has no end-to-end scenario;
  - the haptic of a failed publication.
- **The capture files stay in the cache**, the full-size photograph next to its reduction, until the
  system clears it.
