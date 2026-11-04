# Android catches up with iOS 1.9.0

Shipped on 2026-11-04 on `sprint/android-1-3-0`, from tasks #21, #22 and #23 of the sprint « Android 1.3.0 », one
commit each, straight on the sprint branch (no task branch, no task PR). It ports to `Recit_Android/` the reader's
profile with its tabs ([0064](0064-a-friends-profile-with-tabs.md), [0066](0066-a-friends-profile-tabs-as-pages.md),
[0067](0067-a-friends-profile-presentation-tab.md)), the lists of my network
([0068](0068-lists-in-my-network.md)), a list's Présentation tab ([0073](0073-a-lists-presentation-tab.md)) with the
pager of [0075](0075-lens-tabs-and-a-lists-pager.md), « Modifier l'œuvre » and « Modifier l'auteur·ice »
([0057](0057-edit-works-and-authors.md)), and the dark form cards ([0054](0054-forms-on-the-book-screens-dark-cards.md)).
Shipping it to the Play Store is #20.

Left out on purpose: Wikidata ([0070](0070-wikidata-account-and-editing.md)) and 0075's lens. The tabs are a plain
sliding capsule.

## What it does

**A friend's profile** opens on a header holding their picture at 96 dp and their name. Under it, a capsule:
« Inventaire • N », « Listes • N », « Présentation ». The count line under the name is gone. The three are pages side
by side, turned by a swipe or a touch on the capsule, which follows the finger. Each page keeps its own scroll.
- Scrolling folds the header: the picture shrinks to 48 dp into the bar's row, the name goes from `title200` to
  `title50`. A scroll that stops halfway snaps to the nearer end. The bar's ground and hairline show only once folded.
  The fold is blended across pages as they slide.
- Inventaire holds their étagères, then their books.
- Listes holds their lists, in the Lists tab's rows. None → « X n'a pas encore de liste ». They are fetched each time
  the profile opens, and when an invitation from them is accepted, wherever it is accepted; the page shows a spinner
  meanwhile.
- Présentation holds the bio in a selectable card. None → « X n'a pas encore écrit de présentation ».
- A reader who is not a friend gets one page: the bio centred on top, then the relation actions.

**A friend's list is read-only.** No « Modifier », no add bar, no « Déplacer », no « Retirer de la liste ». Their
comment is plain selectable text, shown only when they wrote one.

**Mine only.** The Lists tab's « Mes listes », the book's « … », the work screen's lists, « Déplacer », the account
deletion count and the Profil's list count never show a friend's list.

**The Lists tab** reads « Mes listes » by name, then « Dans mon réseau », my friends' lists, the most recently changed
first. Headers show only when the network has lists. A friend's row starts with a line above the name: their picture
at 16 dp, their name and the count (« Léa • 14 œuvres »). The description runs to three lines. It opens read-only and
has no swipe to delete. The search filters both sections; a section left empty disappears. With no list of mine but
some in the network, a tinted « Créer une liste » row heads the tab.

**A list** opens on « Livres • N » (« Auteur·ices • N » for authors) | « Présentation », pinned under the bar. A swipe
outside the covers turns the page; the cover flow keeps its own swipe. The add bar lives on Livres and slides with it.
The pages are frozen while a comment is written. Présentation shows the description with its links, then Type,
Visible par in words (groups included), Créée le, and Modifiée le once changed. No description → « Cette liste n'a pas
de description ». A list of publishers gets the same two pages, Livres saying it is empty.

**« Modifier l'œuvre »** opens from « Édition de » in « Modifier l'édition », for an inventaire.io work: titles per
language and « Ajouter le titre dans une autre langue », type, form, original language, first publication, authors and
every role, series and rank, genres and subjects, links to other works, 20 catalogues, links on the web, « À ne pas
confondre avec ». **« Modifier l'auteur·ice »** opens from any list of names: names per language, pseudonyms, writing
languages, dates, movement, influences, 29 catalogues, 11 kinds of link.
- Each screen has its own « Enregistrer ». Saving is server-first. A refusal shows a banner; « Réessayer » sends only
  what has not landed.
- Back with unsaved changes asks « Quitter sans enregistrer ? ».
- After a save, « Édition de » and the book screen show the new values.
- A Wikidata work or person shows no way in.
- The work is no longer saved with the edition: « Modifier l'édition » no longer renames a work or changes its
  authors. Its old title-and-authors page only serves a work being created.

**Dark form cards.** In dark, a form's cards are a 40 % black veil (`backgroundFormCell`) on a `gray/800` ground
(`backgroundForm`), on every form built on `FormSection`: « Modifier l'édition », the entity pages, the scanner's
« Nouvelle édition ». The book screen uses the same two. Light is unchanged.

## Technical surface

- **Room 1 → 2** by `AutoMigration`: nullable `users.bio` and `lists.creatorId`. `schemas/…/2.json` is committed.
  Android 1.2.0 shipped schema 1, so the cache survives the update.
- **List ownership** (`data/`): `EntityList.isCreatedByMe(myUserId)` — no creator stamped, or me.
  `ListRepository.observeMyLists()` / `observeMyCount()` / `observeListsOf(userId)` / `observeAllLists()`.
- **Scoped pruning**: the pure `data/lists/ListSyncPlan` deletes only among the creators a sync asked about — mine,
  one friend's (`syncFriendLists`), or a batch of friends (`syncNetworkLists`). A friendship that ends, in the app or
  elsewhere, deletes that reader's lists.
- **Network sync**: `GET /api/lists/by-creators?users=a|b|…&with-elements=true`, 50 friends per request
  (`ListCreatorBatches`), one after another; a failure stops the rest. `SessionCoordinator` runs it after my lists,
  outside the sync status. Only `UserRelation.Friend` counts.
- **Lists tab**: the pure `ListsTabSections` splits and orders the two sections; `ListRow` and `ListRowFeed` are shared
  with the friend's Listes page. `NetworkListEntry` carries the owner.
- **Profile** (`ui/network/`): `UserProfile*`, `UserInventoryPage`, `UserListsPage`, `UserPresentationPage`,
  `UserClosedPage`, `UserViewModel`. `SessionCoordinator.acceptFriend` marks the reader in `friendsSyncing` while
  their books, étagères and lists arrive; a second accept meanwhile is ignored. The header is an overlay over a `HorizontalPager`; the pure
  `ProfileHeaderCollapse` holds the fold, the snap and the room a short page needs at its foot to fold whole. A drag
  during the snap interrupts it without ending it. Each page has its own `LazyListState`.
- **Shared tabs**: `ui/common/CapsuleTabs` draws the capsule from the pager's position, in `backgroundTinted` /
  `foregroundTinted`. `NetworkSegment` stays on Réseau.
- **List screen**: `ListDetailTab`, `ListPresentationPage`, `ui/common/WebLinks` for the description's links.
- **Design system**: `content200` (Alegreya Medium 15 sp), `ThumbnailSize.XXSmall` (16 dp), `backgroundForm`,
  `backgroundFormCell`, `backgroundShade`, and the Android-only `backgroundBook`.
- **Entity editing** (`data/creation/`): `WorkProperties`, `HumanProperties`, `EditionPropertyCatalogue` (one table per
  entity type), `EditionPropertyChoice`; value kinds `AnyEntity`, `Choice`, `Text`, `Ordinal`. `EntityEdit` turns the
  form into one `update-claim` per changed claim (old and new for a single value, one add or remove per value
  otherwise), then one `update-label` per changed label. `EntityCreationRepository.editableEntity` / `saveEntity`
  share their step loop with `saveEdition`. Screens: `EditEntityPage`, `EditWorkForm`, `EditAuthorForm`,
  `EntityFormRows` in `ui/editedition/`.
- **Strings**: French only, copied from iOS, in `strings_network.xml`, `strings_lists.xml` and the new
  `strings_edit_entity.xml`.

## Notable decisions

- **One branch for the three tasks**, at Olivier's request: the board's cards were moved by hand.
- **AutoMigration, not a destructive fallback**: 1.2.0 users keep their cache and their offline books.
- **The friend filter of the Lists tab sits in its view model**, over every stored list and the friends, split by a
  pure type — as iOS does, and unit-tested — rather than a store query.
- **A sparse answer never clears a bio**: a bio emptied on the server stays on the phone until the user is fetched
  whole.
- **`backgroundBook`** exists only on Android: iOS's form ground would have turned the white book screen grey in light.
- **Wikidata works no longer open an editor** from « Édition de »: iOS opens one there thanks to 0070, which is not
  ported.

## Not done, not verified

- **Never seen running.** Built and unit-tested only (`./gradlew assembleDebug :app:testDebugUnitTest`). The fold,
  the snap, the swipes, the capsule, the network lists and the entity screens were never seen on an emulator or a
  device. Nothing was saved to inventaire.io. Dark mode was never looked at.
- **No migration test**: `MigrationTestHelper` needs `room-testing`, a new dependency. The update over a real 1.2.0
  install was not tried.
- **The e2e** (`scripts/e2e-android.sh`, `build/e2e-android/20261104-205613/`) ended 12 OK / 16 KO, every KO from
  « Ranger mes livres » onwards, a screen these commits do not touch, while the Mac's load reached 293 with two iOS
  simulators booted. Not rerun. The scenario does not reach any screen of this work.
- **Not ported**: tappable links in a reader's bio; the tab groups' screen-reader labels; tab labels shrinking before
  wrapping; the pager frozen while a book is picked off an étagère; initials in a 16 dp avatar (a grey disc); links on
  bare domains without `www.`; the fade of a list under its tabs; label languages beyond iOS's 27.
- **Unverified**: at the first or last cover, one more swipe may turn the list's page.
