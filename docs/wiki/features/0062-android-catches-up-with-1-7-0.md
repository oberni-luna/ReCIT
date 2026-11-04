# Android catches up with iOS 1.7.0

Shipped on 2026-10-30, from PRD 0030 and issues 0145–0151, in an autopilot run, on the branch `android-1.7.0`; seven
commits, one per issue. It ports to `Recit_Android/` everything iOS 1.7.0 shipped between « 1.6.0, build 17 » and
« 1.7.0, build 18 »: the language filter and the faster sync of « Éditions » ([0058](0058-editions-language-filter.md)),
the spinner after a section header ([0059](0059-section-loading-indicator.md)), a list as a cover flow with its two
ways to add a book ([0060](0060-list-cover-flow.md)), moving a book to another list
([0061](0061-move-to-another-list.md)), the red removal swipes, and an ISBN typed in Recherche. The PRD and the issues
were scaffolding and were never committed; they were numbered past every number git history has seen.

The one 1.7.0 change not ported is the duplicates review's lighter re-read after a merge (`82c639f`): Android has no
duplicates review ([0051](0051-edition-duplicates.md)).

## What it does

**The removal swipes are red.** « Retirer de … » on an étagère and in « Ranger mes livres », and « Supprimer » on the
Lists tab, sit on `foregroundError`, their label and icon in `foregroundInverse`. They drew the accent's dark green
and a pale pink. The swipe of a list's element is gone with the rows it was on.

**An ISBN in Recherche opens its edition.** A query that is nothing but an ISBN with a right check digit — hyphens
and spaces allowed, an ISBN-10 turned into its ISBN-13 — is not sent to `/api/search`, which read
« 978-2-234-09688-2 » as the numbers 978, 2, 234… It is resolved through `isbn:` with `autocreate`, the scanner's
call. Its edition shows under « Livres » and opens the book screen on that very edition. Anything else, a mistyped
ISBN included, still goes to the text search; so does the people-only suggestion.

**« Éditions » by language.** At the right of « Éditions de … », the language shown, in green, with an unfold glyph.
Its menu offers « Toutes les langues » with the total, then each language present by number of editions, named in
the phone's language, then « Langue non renseignée » when some editions have none. A check marks the one shown; the
counts are a second line. By default the phone's language is shown when the work has editions in it, and every
edition otherwise. Until somebody picks one, the default follows the editions as they arrive. The pick lasts as long
as the screen. The language is the edition's own `wdt:P407`, never guessed.

**« Éditions » fills as it loads.** The editions the store lacks are fetched 50 at a time and written batch by batch,
so a work of thousands of editions fills under the reader's eyes rather than at the end.

**A spinner after « Œuvres de … » and « Éditions de … »**, small and grey, for as long as the author screen or the
work's screen is asking inventaire.io for more. On an empty « Éditions », the list's own spinner stands in for it.

**A list as a cover flow.** A list of works or of authors opens on its covers in a strip that snaps; the one facing
the reader is the selection. The others are turned in perspective, their inner edge receding, pushed aside and
shaded more with each rank. Authors are portraits in discs, their initials without one. A swipe moves one book at
most. Tapping a turned cover brings it to the front; tapping the one in front opens its page. Below it, cross-fading
from one book to the next:
- the title, and the authors (or what inventaire.io says an author is);
- « Mon commentaire », written when the field is left — focus lost, the keyboard's « OK », or the book swiped away;
- « Déplacer dans une autre liste », when there is another list of the type;
- « Retirer de la liste » in red, and « Ajouté le … » under it.

A list of publishers still says it is empty.

**« Ajouter un livre »** over « Scanner » and « Rechercher » is pinned at the foot of the list, above the tab bar.
For a list of authors it reads « Ajouter un·e auteur·ice » over « Rechercher » alone. It steps aside while the
comment is written. Both ways in add one book and close, and the list lands on it.
- **Rechercher** opens a sheet. From three characters it shows « Dans mes livres et chez mes amis » (five at most),
  then « Œuvres sur inventaire.io », or « Auteur·ices sur inventaire.io » alone for a list of authors. A « + » adds
  the result. What the list holds carries a check and is shown instead. A copy is added as its work.
- **Scanner** opens the camera full screen. The recognised book rises with the batch scanner's round « + ».
  A book the list holds raises « Ce livre est déjà dans « … » », with « Le voir » and « Continuer ». An unknown
  edition, or one without a work, is said on the row and nothing more.
- From either, an edition of several works asks « Laquelle ajouter à « … » ? », with « Toutes les œuvres » last.

**Moving to another list.** « Déplacer dans une autre liste » opens a menu of the user's other lists of the same
type, sorted by name. A list that already holds the book is greyed, with « Déjà dans cette liste » under its name.
Picking one moves the book with its comment, and a snackbar says « Déplacé dans « … » ». The row spins meanwhile. It
is inert while the comment is being written and for an element the server has not created yet.

## Technical surface

- **Pure, ported from iOS and tested** (`data/`): `search/IsbnQuery`, `book/EditionLanguageFilter` (with its
  `Option`), `lists/CoverFlowGeometry`, `lists/CoverFlowSelection` (iOS's `keepSelection`), `lists/ListAdditionPlan`,
  `lists/ListMoveDestination`. 24 new tests; the suite runs 525, all green.
- **Swipes**: `ShelfScreen.RemovableRow`, `SortShelfScreen.RemovableBookRow`, `SwipeToDeleteRow`.
- **Search**: `SearchResult.Type.Editions`, never asked of `/api/search` (`SearchRepository.search` now defaults
  to works and humans). `SearchViewModel.remoteResults` looks an ISBN up; `SearchContent` lists editions under
  « Livres » and pushes `BookAnchor.Edition`.
- **Éditions**: `WorkViewModel` keeps `chosenLanguage` (`null` until a pick) and builds an
  `EditionLanguageListing` on each change of the editions or the pick. `WorkUiState` gains `editionCount`,
  `language`, `languageOptions` and `isRefreshing`. The menu is `ui/book/EditionLanguageMenu`, a `DropdownMenu`.
  `EntityRepository.syncWorkEditions` reads the held editions 500 uris at a time (SQLite before 3.32 caps a
  statement at 999 arguments), then fetches the rest in batches of 50, each linked to this work only.
- **Spinner**: `SectionHeader(isRefreshing:)` and `SectionLoadingIndicator` in `designsystem/Components.kt`, labelled
  « Mise à jour en cours ».
- **Cover flow** (`ui/lists/`):
  - `ListCoverFlow` is a `HorizontalPager` of empty 64 dp slots (`PageSize.Fixed`, `PagerSnapDistance.atMost(1)`).
  - The covers are drawn under it, posed in `graphicsLayer` from `currentPage + currentPageOffsetFraction`, so a
    frame recomposes nothing. Their `zIndex` follows the rank.
  - Taps are hit-tested against the drawn covers, nearest the centre first.
  - The pager reports only the pages a swipe settles on, and follows the selection when an add or a removal moves it.
- **List screen** (`ui/lists/`): `EntityListScreen` holds the cover flow content, `ListAddBar` as the `Scaffold`'s
  `bottomBar`, and the sheet and scanner. `ListCommentField` is a `BasicTextField` with `ImeAction.Done`.
  `ListCard` is a grouped cell.
- **List view model**: `EntityListViewModel` keeps the selection as a uri. Its rows carry `elementId` and `created`.
  It offers `add`, `requestSelection`, `updateComment` and `move`, and works out the destinations from every list
  in Room.
- **Adding** (`ui/lists/`): `ListAddSearchSheet` is a `ModalBottomSheet`, searching 300 ms after typing, with
  `InventorySearchRanking` for my books and my friends'. `worksOf` re-reads an edition whose works are unknown.
  `ListWorkChoiceDialog`. `ListScanScreen` is a full-screen `Dialog` over `BarcodeCameraPreview`, driven by
  `ListScanSession`: `BatchScanStateMachine`'s lookup half, with a ten-second deadline. `ScanResultRow` takes a
  nullable `onCreate` and an `addLabel`.
- **Writes** (`ListRepository`):
  - `updateComment` is optimistic through `OptimisticRunner`. It sends nothing for an unchanged text or an
    optimistic id.
  - `moveElement` is three calls: `add-elements`, `update-element` with the comment, then `remove-elements`.
  - `ListDao.element(id)` is new.
- **Strings**: about forty in `strings_book.xml` and `strings_lists.xml`, French only like the rest of the app,
  copied from iOS.

## Notable decisions

- **The tab bar stays.** iOS hides it under a list and puts the add bar in its place. On Android the add bar is the
  screen's own bottom bar, above the navigation bar, as Material apps keep theirs.
- **The covers are drawn apart from the pager.** Drawn inside the pages, a cover could not overlap its neighbours in
  the right order, nor be tapped where it shows rather than where its slot is. The pager keeps the fling and the
  snap.
- **`rotationY` is iOS's angle, not its opposite.** Compose turns the other way round from `rotation3DEffect`. With
  the sign copied, the inner edges came forward; seen on the emulator and flipped.
- **No dispatcher switch in the view model.** The language listing first ran under `flowOn(Dispatchers.Default)`;
  Lunabee's Android rules keep context switches in the data layer. The listing is a filter and a sort of a few
  thousand rows, done once per change, not the 30 million pairs that froze iOS.
- **No daily re-read.** iOS re-reads an edition it holds once a day; Android never re-read them, and still
  does not.
- **Server-first move, optimistic comment, optimistic add** — as on iOS, for the same reasons: a move is three calls
  that must not leave the book in neither list.
- **The list's scanner offers no « Nouveau livre »**: the creation form files the book into the inventory too.

## Not done, not verified

- **Never seen signed in.** The emulator's app has no session, and I did not sign in. The cover flow, the search
  sheet and the scanner were seen on a Pixel 8 emulator (API 35, light) in a throwaway harness. It was swapped into
  `MainActivity`, then removed, and never committed.
  - The cover flow showed nine placeholder covers and five author discs. One swipe moved one book. A tap on a side
    cover selected it, and a tap on the front one opened it.
  - The sheet answered « harry potter » from inventaire.io.
  - The scanner showed the camera and its hint.
- **Not seen**: the list screen itself, the comment written and saved, an add or a move for real, the snackbars, a
  greyed destination, the duplicate alert, the collection dialog, « Éditions » and its menu, the spinners, an ISBN
  search, the red swipes, dark mode. Nothing was written to inventaire.io.
- The release (R8) build was not built.
- Figma has no Android frames for any of this.
