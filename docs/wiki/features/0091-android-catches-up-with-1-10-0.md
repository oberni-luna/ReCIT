# Android catches up with iOS 1.10.0

Shipped on 2026-11-10 as Android 1.4.0 (versionCode 6, tag `Android-1.4.0-#6`), from the sprint « Android 1.4.0 »:
#47, #94, #95, #96, #97, #98, #99, #100, #111, #112 and #113, one task branch and one PR each into
`sprint/android-1-4-0`, then #101 for the version and the Play Store. It ports to `Recit_Android/` the private note
([0080](0080-a-private-note-on-my-copy.md)), the tab bar leaving pushed screens
([0088](0088-tab-bar-hidden-on-pushed-screens.md)), the tabbed étagère ([0089](0089-tabbed-shelf-screen.md)), « Dans
les listes » ([0079](0079-the-lists-a-book-is-in.md)), photos full screen ([0081](0081-a-friends-and-a-groups-photo-full-screen.md),
[0085](0085-author-photos-full-screen.md)), a group's photo ([0082](0082-a-groups-photo-from-its-settings.md)),
Nouveau livre from Recherche ([0087](0087-book-creation-from-search.md)), the `429` sentence
([0083](0083-rate-limited-sign-in-message.md)) and profile editing ([0055](0055-profile-editing.md)).

Left out on purpose: the Échanges tab of a friend's profile ([0086](0086-a-friends-transactions-tab.md), Android syncs
no transactions yet), Wikidata account linking ([0070](0070-wikidata-account-and-editing.md)), donations.

## What it does

**Sign-in refused for too many attempts.** A `429` on Connexion says « Trop de tentatives. Réessayez dans quelques
minutes. » under the fields; on Création de compte, in the general error place.

**My copy's private note.** « Dans mon inventaire » on the Fiche livre shows « Ce que j'en pense », then « Ce que je
garde pour moi » (placeholder « Écrire une note privée »), then the date and status row. Written like the Commentaire:
optimistic, one `PUT /api/items/bulk-update` with `attribute: "notes"`, writes of one field on one book queued one
after the other; a refusal puts back the last note the server accepted. A friend's copy never shows a note.

**The tab bar leaves with the push** in Inventaire, Listes and Réseau: it slides down and fades as a screen is pushed
and comes back at the root. Recherche keeps it.

**An étagère in two tabs.** « Livres • N » | « Présentation », turned by a swipe or the capsule. « Ajouter des
livres », pinned under Livres on mine, opens a sheet of my books not on it: tick, search by title or author without
losing ticks, « Ajouter N livres » files them in one optimistic `add-items`. A book is taken off by swiping its row
past half its width; a shorter fling springs back. Présentation shows the description, Visible par, Créée le,
Modifiée le. A friend's étagère has no button and no swipe.

**« Dans les listes »** on the Fiche livre: my lists and my friends' lists of works holding the book, the most recently
updated first, a friend's row headed by their picture and name; absent when none. A tap opens the list on its first
book, scrolls to this one, fades a halo in and vibrates once; with animations off it opens on the book.

**Photos full screen.** A friend's photo at rest, a group's header photo and an author's photo open the Plein écran
(fit, double-tap, pinch, pan, swipe down). A photo that did not load, and the folded friend's photo, open nothing.
Behind it, Android 12+ blurs the screen under a light or dark veil; Android 9–11 gets an opaque light or dark ground.
Book covers get the same ground.

**A group's photo** is set, replaced or removed in Réglages du groupe (Appareil photo, Photos, Retirer), sent on
« Enregistrer »: upload to `container=groups`, then `update-settings picture`; server-first. Closing the sheet sends
nothing.

**Nouveau livre from Recherche.** « Aucun résultat » on inventaire.io offers « Ajouter ce livre », opening Nouveau
livre full height on the query (or on the typed ISBN). The ISBN is optional there; a wrong check digit disables
« Publier ». Drafts are kept per query in memory. The language deduced from a typed ISBN follows the ISBN.

**Profile editing.** « Modifier le profil »: picture (camera, gallery, Gravatar, remove), username checked while
typing, bio (1 000 characters), position placed on an OpenStreetMap map and rounded to two decimals. « Compte et
connexion »: address (server-first, with the confirmation card and « Renvoyer »), password, language, « Visible sur
le fédivers », anonymous contributions — switches optimistic. « Notifications par e-mail »: the general switch, the
summary and its frequency, ten switches in three groups. Every `PUT /api/user` goes through one pacer, 1.1 s apart.

## Technical surface

- `auth/model/AuthFailure.RateLimited`.
- `data/inventory/` (`InventoryItemTextAttribute`, `InventoryItemTextWriter`): Room 2 → 3 by `AutoMigration`
  (`inventory_items.notes`).
- `AppTab.hidesTabBarOnPush`, `MainScaffold`'s `AnimatedVisibility` bar; pushed forms consume their insets.
- `data/shelves/ShelfMembership` (injected from `AppContainer`), `ShelfAddBooksSheet`, `ui/common/PresentationPage` +
  `ListCard`, `designsystem/GroupedCell`.
- `data/lists/BookListEntry`, `ListArrivalFocus`, `ui/book/BookListsSection`, `Destination.EntityList(id, focusUri)`,
  `ui/common/ReducedMotion`.
- `ui/common/FullScreenCover`, `FullScreenBackdrop.of(sdk, blurEnabled)`, `EnlargeablePhoto`,
  `TapSharedWithSiblings` (the tap shares input with the pager).
- `data/images/ImageUpload` + `ImageContainer` (entities, groups), `ui/editedition/ImageSourceMenu` and its
  `MenuLine`, `GroupSettingsDraft`.
- `data/creation/NewBookOrigin`, `NewBookDrafts`, `ui/createbook/NewBookCreation` (shared by Scan and Recherche).
- `data/user/` (`RequestPacer`, `ProfileRepository`, `AccountRepository`, `AccountSettings`, `NotificationSetting`,
  `EmailChangeFailure`), `data/CachedPicture`, `ui/profile/edit/`, `ui/profile/account/`,
  `ui/editedition/MenuPropertyRow`, `designsystem/SwitchRow(contentPadding, enabled)`; osmdroid 6.1.20.
- 729 unit tests at the last task's landing.

## Notable decisions

- Each task was reviewed once more at landing; about 45 findings were fixed, among them a duplicate `LazyColumn` key
  that crashed every owned book's Fiche livre, and a page swipe on an étagère that took a book off it.
- A flick that starts on one of my étagère's rows goes to the row, not the pager — as on iOS, where `.swipeActions`
  sits inside `TabPager`.
- The swipe-to-remove uses Material3 1.4.0's deprecated `SwipeToDismissBoxState` constructor on purpose: the current
  one lets any fling remove.
- Play's Data safety gains Location › Approximate location (the profile's position) and widens Photos to group and
  profile pictures ([google-play](../integrations/google-play.md)).

## Not done, not verified

- Nothing was written to inventaire.io by an agent; the review fixes were not retested on a device. The 1.4.0 debug
  build was launched on a Galaxy S22 (Android 16) without a crash.
- The e2e scenario was not run on the final build (last run, before the fixes: 11 OK / 2 KO, the KO being the Fiche
  livre crash since fixed).
- The Play Console upload and the Data safety form are Olivier's.
