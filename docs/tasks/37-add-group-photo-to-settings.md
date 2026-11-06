---
issue: 37
status: to-test
wiki: [[network]], [[book-and-editions]], [[features/0028-network-tab-and-groups]], [[features/0047-new-book-work-first]], [[features/0050-every-bibliographic-datum]]
note: pouvoir modifier l'image d'un groupe depuis les réglages du groupe via le même composant que pour les editions
created: 2026-11-06
---

## Context / Decisions

> pouvoir modifier l'image d'un groupe depuis les réglages du groupe via le même composant que pour les editions

- **What**: an admin sets, replaces or removes the group's photo from Réglages du groupe (`GroupSettingsView`).
  Today the file says « The photo and the place are not offered yet (PRD 0016) »: the photo is offered now, the place still not.
- **Component**: the source menu of the edition's cover (`CreateBookCoverRow`) becomes one shared component, used by the edition forms **and** the group.
  - Sources, in this order: Appareil photo (where there is one), Photos, Fichiers, Image depuis une URL.
  - A photo set → « Retirer » first, then « Remplacer » with the same sources (as `V12`).
  - The edition forms (« Nouvelle édition », « Nouvelle œuvre », « Modifier l'édition ») look and behave exactly as before.
  - The group's slot is **round**, like the group photo everywhere else (`AvatarThumbnail(.group, …)`), not the 2:3 dashed cover frame.
  - Image depuis une URL for a group: the address field, paste and preview of `CoverURLView`, **without** the Google Images search on title + ISBN.
  - Gravatar (the profile's picker) not offered: a group has no email.
- **Place in the form**: first section, above the name.
- **When it is sent**: on « Enregistrer », with the name and the description — nothing uploaded while the admin hesitates.
  - « Enregistrer » is enabled when only the photo changed.
  - Order: `POST /api/images/upload` into container `groups` (the server only accepts `/img/groups/<hash>`), then `PUT /api/groups/update-settings` `attribute: picture`, `value: <path>`.
  - « Retirer » → `value: null` (`picture` accepts null).
  - The sheet closes at once, as today; the group header and rows change when the server answers; a failure → SnackBar, the old photo stays.
- **Out of scope**: a photo at group creation (`CreateGroupView`), the place, Android.

## Acceptance criteria

- Réglages du groupe, as admin: the first section shows the group's photo in a round slot, or an empty round slot inviting one.
- Tap the empty slot → menu Appareil photo (device only) / Photos / Fichiers / Image depuis une URL.
- Pick a photo in Photos → the slot shows it; « Enregistrer » turns enabled with name and description untouched.
- « Enregistrer » → the sheet closes; after the server answers, the group header and its row in Réseau → Groupes show the new photo; another device sees it after a sync.
- Slot with a photo → menu starts with « Retirer », then « Remplacer » and the sources. « Retirer » + « Enregistrer » → the group shows its glyph again.
- Image depuis une URL: paste an image address → preview → « Utiliser cette image » → the slot shows it; no Google search button.
- Close the sheet (×) after picking a photo → nothing is uploaded, the group keeps its photo.
- Server refuses or network down → SnackBar, the group keeps its old photo.
- « Nouvelle édition » and « Modifier l'édition »: the cover row looks and works as before (2:3 frame, same four sources, ISBN beside it).

## Implementation

Round 1 · autopilot · 2026-11-06

- **Shared menu** — `Features/Components/ImageSourceMenu.swift` (new): generic over its label; camera, Photos, Files, URL, « Retirer » + « Remplacer »; every pick through `CoverImageReducer`. `CreateBookCoverRow` uses it: frame, ISBN column, a11y label and id unchanged. Strings `create_book.cover.{camera,photos,file,url,replace}` renamed in place to `image_source.*`, same text.
- **URL screen** — `CoverURLView` keeps `init(searchedTitle:isbn:onUse:)` for the editions (search, notice, « ? » as before) and gains `init(onUse:)`: address, paste, preview only. The Google section moved to `Features/CreateBook/CoverURLSearchSection.swift`.
- **Setting** — `GroupSetting.picture(String?)`, `Value.null` encodes JSON null; `applied(to:baseUrl:)` makes the path absolute.
- **Draft** — `Model/Groups/GroupPictureEdit.swift`: `.unchanged / .replaced(Data) / .removed`, `isChange(from:)`, `showsPicture(savedPictureURL:)`.
- **Write** — `AppModels/Group/GroupModel+Picture.swift`: `updatePicture(_:on:modelContext:)`, server-first in a model-owned task: upload into `groups` → `update-settings picture` → place the absolute URL; failure → `errorReporter`, old photo stays. Removal sends null, uploads nothing.
- **Form** — `GroupSettingsView`: photo section first (`GroupPhotoPicker`, `GroupPhotoPreview`, id `e2e.groupSettings.picture`), URL screen pushed by `navigationDestination(isPresented:)`, « Enregistrer » enabled by any change incl. the photo. Strings `groups.form.picture.{add,change,remove}`.
- **Divergence from the task**: the slot is a 104 pt `AvatarThumbnail(.group)`, a rounded square (corner `.medium`), not a circle — group photos are rounded squares everywhere in the app. A circle is one clip in `GroupPhotoPreview`.
- **Lint baseline**: `GroupModel.swift` is pinned at 486 lines by `file_length`/`type_body_length` reasons, hence the extension file; statics and `dropping` moved (clears its `type_contents_order` entries), `apiService`, `place`, `putSetting`, `inFlightTask` setter made internal. `CoverURLView` keeps two inits because `EditEditionFlowView`'s body length is pinned too.
- Build ✅ (ReCIT_iOS, iPhone 17, SwiftLint). Tests ✅ 49/49 — GroupPictureTests (10 new), GroupModelTests, GroupModelAdministrationTests, ReaderGroupTests, GroupPersistenceTests.

## Review

## Verification

Round 1 · autopilot

- ⚠️ Not run by agent: no UI-automation tool reached the simulator, and the simulator holds a real account. Nothing uploaded or saved to inventaire.io. Covered by tests: upload container and order, null on removal, failed upload never writes, refused write keeps the old photo and reports.

## Feedback
