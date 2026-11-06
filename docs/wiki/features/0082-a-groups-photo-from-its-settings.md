# A group's photo, set from its settings

Shipped on 2026-11-06, iOS only (issue #37). Réglages du groupe (`GroupSettingsView`) let an admin change the name
and the description, but not the photo (PRD 0016 had left it out). Now an admin sets, replaces or removes it there.

## What it does

- The first section of Réglages du groupe shows the group's photo, or an empty slot that invites one. The slot is a
  104 pt `AvatarThumbnail(.group)`. The task asked for a circle, but the slot is a rounded square, because group
  photos are rounded squares everywhere else in the app.
- A tap opens the same source menu as an edition's cover: Appareil photo (where there is one), Photos, Fichiers,
  Image depuis une URL. With a photo set, the menu starts with « Retirer », then « Remplacer » and the sources.
- Image depuis une URL for a group has the address field, paste and preview, without the Google Images search that
  the edition forms offer.
- Nothing leaves the phone before « Enregistrer ». « Enregistrer » is enabled when only the photo changed. Closing
  the sheet uploads nothing.
- On « Enregistrer » the sheet closes. Then, server-first:
  1. `POST /api/images/upload` into the `groups` container.
  2. `PUT /api/groups/update-settings` with `attribute: picture` and the returned path.
  3. The group's header and its row show the new photo.
- « Retirer » sends `value: null` and uploads nothing.
- If the server refuses or the network is down, a SnackBar shows and the group keeps its old photo.
- The edition forms (« Nouvelle édition », « Nouvelle œuvre », « Modifier l'édition ») look and behave as before.

## Technical surface

- `Features/Components/ImageSourceMenu.swift`: the source menu lifted out of `CreateBookCoverRow`, generic over its
  label. Every pick goes through `CoverImageReducer`. The strings were renamed in place from `create_book.cover.*`
  to `image_source.*`, with the same text.
- `Features/Components/CoverURLView.swift`: the address, paste and preview screen, generic over a `@ViewBuilder`
  head. The group uses it bare. The edition forms use `Features/CreateBook/BookCoverURLView.swift`, which adds the
  bibliographic-data notice, the Google Images search (`CoverURLSearchSection`) and the « ? ».
- `CoverCaptureView`, `CoverImageReducer`, `CoverURLPreview`, `CreateBookSectionHeader` and
  `CreateBookSectionFooter` moved from `Features/CreateBook/` to `Features/Components/`, since the group uses them too.
- `Model/Groups/GroupSetting.swift`: `picture(String?)`; `Value.null` encodes JSON null.
- `Model/Groups/GroupPictureEdit.swift`: `.unchanged` / `.replaced(Data)` / `.removed`, the draft of the form.
- `AppModels/Group/GroupModel+Picture.swift`: `updatePicture(_:on:modelContext:)`, in a model-owned task. It is in
  its own file because the SwiftLint baseline pins `GroupModel.swift` at exactly 486 lines. For that file to reach
  them, `place`, `putSetting`, `write`, `apiService` and the `inFlightTask` setter are internal, not private.
  Olivier accepted this; a separate task splits `GroupModel`.
- A refused name or description now puts back only its own attribute on the group as it is
  (`GroupSetting.held(by:)`), so it never undoes a photo that landed in the same « Enregistrer ».
- `Features/Network/Groups/GroupPhotoPicker.swift` and `GroupPhotoPreview.swift`, identifier
  `e2e.groupSettings.picture`.
- Tests: `GroupPictureTests` (upload container and order, null on removal, a failed upload never writes, a refused
  write keeps the old photo and reports, a refused name keeps the photo that landed first).

## Not done

- A photo at group creation (`CreateGroupView`), the group's place, Android.
- No photo was uploaded or saved to inventaire.io by the agent: the simulator holds a real account. e2e was not run.
