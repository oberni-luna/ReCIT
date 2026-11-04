# The cover full screen, editions added and edited, a book row's long press — on Android

Shipped on 2026-10-27, from PRD 0029 and issues 0141–0145, in an autopilot run, on the branch
`android-cover-zoom-edition-edit-context-menu`; five commits, one per issue, plus a sixth, asked for
during the run, that reads the search score as `_score`. It ports to `Recit_Android/` four things iOS
already had: the full-screen cover of [0029](0029-full-screen-cover.md), the long-press menu of every
book cell (`bookActions(placement: .contextMenu)`), « Modifier l'édition » of
[0049](0049-edit-an-edition.md) and [0050](0050-every-bibliographic-datum.md), and the scanner's
work-first « Nouveau livre » of [0047](0047-new-book-work-first.md) and 0050, which replaces the
title-and-one-author form of [0043](0043-android-create-a-missing-book.md). The PRD and the issues were
scaffolding and were never committed; they were numbered past every number git history has seen.

## What it does

**The cover, full screen.** A tap on the cover of the entity header — the book screen, the work's
edition picker, the header shown while a searched book resolves — opens the cover alone on black,
fitted edge to edge. A header with no image has nothing to tap.
- Double tap goes from fitted to filled, and from anything else back to fitted.
- Pinch magnifies from fitted up to ×4, or up to filled when that is larger.
- Drag moves a magnified cover; it is off when fitted.
- Swipe a fitted cover down by more than 15 % of the screen, or tap « Fermer », to close.
- TalkBack reads « Agrandir la couverture » on the header, « Couverture » on the full-screen image.

**A book row's long press.** Every `InventoryItemRow` — the inventory, an étagère (both of its rows),
a friend's profile, Recherche, its local results, « Chez mes amis » — opens the book screen's « … »
menu on a long press, anchored on the row, with a haptic tick. My copy: Étagère ▸, Liste ▸ (an
edition of exactly one work), Supprimer, which asks first. Somebody else's: Liste ▸, Ajouter à mes
livres. The snackbars are the book screen's, « Voir » included. A tap still opens the book.

**« Données bibliographiques ».** The book screen ends on one tinted row and the open-data note under
it, for every edition but a Wikidata one. It pushes **« Modifier l'édition »**, read fresh from
inventaire.io, with a spinner and « Réessayer ». The sections follow iOS 0050:
- the notice and its « ? »;
- « Édition de »: the works, « Ajouter une œuvre », a swipe to detach, a tap to « Modifier
  l'œuvre » (title and authors; a Wikidata work read-only);
- « Couverture et ISBN »: the cover from the camera app or the gallery, or removed; ISBN-13 and
  ISBN-10 read-only;
- « Titre », « Publication » (publisher, collection, date, language), « Format » (six formats,
  pages, volumes), « Ont aussi fait cette édition » (six roles), « Bases bibliographiques » (22
  catalogues, checked as typed), « Sur le web » (ten kinds of link).

Entity pages search as you type and end on « Créer « … » » (not for a language; a collection only
under a publisher). A property that already names someone opens its values first. « Enregistrer » is
pinned and enabled as on iOS. The save waits for the server. On success the screen pops and the book
screen shows the change. On failure, what landed is written to the store anyway, a banner says which
of the three cases it was, the draft stays, and « Réessayer » sends only the rest.

**« Nouveau livre » from the scanner.** The unknown row's creation opens on a search for the work.
- A work found leads to « Nouvelle édition » with that work.
- « Créer l'œuvre « … » » leads to « Nouvelle édition » with « Nouvelle œuvre » over it: the work's
  title and authors.
- « Nouvelle édition » is the edit screen's sections in creation mode: the cover and ISBN from the
  barcode, the title from the work, the language from the ISBN, and every property. Touching a found
  work goes back to the search; a swipe detaches it.
- « Publier et ajouter à mes livres » is pinned, with « Garder le brouillon » under it after a
  failure.
- The order is the cover upload, then the entities the edition names created once, then the dry run
  and « Œuvre déjà connue » (only when no work was picked; a picked work is named in `resolve`), then
  `resolve`, then the item.
- A failure shows on the page that published. Drafts are still kept by ISBN, everything typed included.

## Technical surface

- **Cover** (`ui/book/`): `CoverZoom`, the pure gesture maths, and `FullScreenCover`, a `Dialog`
  driven by `awaitEachGesture`. `ImageUrl.fullScreen` raises a Wikimedia `width` to 2048. The header
  is in `EntityComponents.kt`.
- **Long press** (`ui/book/`): `BookActions` holds the menu's reads and its four writes, keyed by
  edition uri. `BookMenuLine.of(…)` is the pure line builder. `BookActionsHost` owns the confirmation
  and the creation sheets, and `InventoryItemRowWithActions` is the row. `MoreActionsMenu` splits into
  `ActionsDropdown`, which takes any anchor. `BookRow` gains `onLongClick` through `combinedClickable`.
- **Data** (`data/creation/`, ported from iOS `Model/Creation/`): `EditionProperty` (the catalogue),
  `EditionProperties`, `EditionClaimValue`, `EditionEntityValue`, `ClaimLiteral` (numbers go out as
  JSON numbers), `PublicationDate`, `EditionFormat`, `EntityCreationKind`, `EditionClaims`,
  `EditionWork`, `WorkEdit`, `EditionEdit` with `nextStep`, `EditionClaimUpdate`, `EntityLabelUpdate`,
  `EntityImageHash`, `EditionSaveResult`, `EditionStoreUpdate`, `NewBookAuthor`, `WorkCandidate`.
  `NewBookDraft` and `ResolveRequestBuilder` carry the chosen or new work, several authors and every
  property.
- **Repository**: `EntityCreationRepository` gains `editableEdition`, `describeEditionWorks`,
  `searchEntities`, `searchWorks`, `createEntity`, `createPendingEntities` and `saveEdition` (a loop
  over `nextStep`, capped at 100). `EntityRepository.applyEditionEdit(localUri, after, before)` writes
  the result to Room, with two new DAO unlink queries and no schema change.
- **Screens**:
  - `ui/editedition/`: `EditEditionViewModel`, the sections (`EditionFormSections.kt`), the pages
    (`EditionPropertyPages.kt`, `WorkPages.kt`), the building blocks, `PageStack`, `DebouncedSearch`,
    `EditionFormRules`, `EditionPropertyLabels`.
  - `Destination.EditEdition(uri)`.
  - `ui/createbook/`: `CreateBookPage` (the creation's stack), and `CreateBookSession` /
    `CreateBookScreen`, both rewritten over the shared sections.
- **Strings**: `strings_edit_edition.xml` is new; `strings_book.xml` and `strings_create_book.xml`
  have grown. All French, from `Localizable.xcstrings`.
- **Tests**: 501 JVM tests, all green, up from 349. The new suites are `CoverZoomTest`,
  `FullScreenImageUrlTest`, `BookMenuLineTest`, `SearchScoreDecodingTest`, `EditionPropertiesTest`,
  `EditionEditTest`, `EditionEditWorkTest`, `EditionClaimsTest`, `NewBookDraftTest`,
  `WorkCandidateTest`, `EntityCreationRepositoryEditionTest` (MockWebServer), `EditEditionPageTest`,
  `EditionFormRulesTest`, `EditionPropertyLabelsTest`, `DebouncedSearchTest` and `CreateBookPageTest`.

## Decisions worth knowing

- **Pages are a stack in a view model's state, not destinations.** The form and its pickers share one
  draft, and `CreateBookScreen` already worked that way. Only « Modifier l'édition » itself is pushed.
  It is a screen with a back arrow, where iOS uses a sheet.
- **Nothing is optimistic.** The data is public, as on iOS. A partial failure still writes what landed
  to the store, so the book screen never lags behind the server.
- **The menu's writes run on the application scope.** A row can scroll away, or vanish because of its
  own deletion, and the server call must not be cut off with it. Room is read only while a row's menu
  is open.
- **Pickers search through `EntityCreationRepository`**, with an `EntitySearchType` of its own.
  `SearchResult.Type` is matched exhaustively by Recherche, so it was left alone.
- **In creation, the new work's authors go through `resolve`, as on iOS.** Only the publishers,
  collections and people the edition names are created first, through `POST /api/entities`. In « Modifier
  l'édition », everything new is created that way.
- **The resolve request changes twice, as in iOS 0047.** A known work is named in `works`, and an
  uploaded cover is sent absolute.
- **`_score`.** `/api/search` sends the score under that name, and the Android DTO read `score`, so
  results were never sorted. This is half of iOS `12bc1d4`. The other half, a double-encoded `|`,
  never applied here: `HttpUrl` encodes once.

## Divergences from iOS

- Covers come from the camera app or the gallery, never from a web address or Files.
- « Différente de » is not done, as on iOS.
- « Emprunter à » is not in the menu: Android never had it.
- The menu opens at the row's edge, not at the finger.
- Pinch scales around the screen's centre, there is no rubber-band past the limits, and closing does
  not fade.
- The help is a page of the stack, not a sheet.
- A day-precise date uses Material's `DatePicker`, from 1450 to next year.
- The scanner's search is empty-titled « De quel livre s'agit-il ? », which is iOS's
  `create_book.search.empty.*`.
- In « Nouvelle œuvre », the last author can be swiped away. The draft then cannot be published, and
  the footer says why.
- Tapping an author does not reopen the picker to replace them.

## Not done, or not verified

- **Never run.** Every commit builds and its unit tests pass. No screen has been seen on a device or
  an emulator, so a lot is unchecked by eye: the gestures, the long press and its anchoring, the
  swipes, the menus, the date picker, the save flow and the creation flow.
- **Nothing was written to inventaire.io.** Saving and publishing were tested only against
  MockWebServer, because every edition is public.
- **No Compose UI test, and no session-level test of publishing**, as the project has none.
- `lintDebug` still fails on older errors in other files; none of them is in a touched file.
