---
issue: 99
status: to-test
wiki: [[features/0082-a-groups-photo-from-its-settings]], [[features/0046-android-groups]], [[features/0052-android-cover-zoom-edition-editing-context-menu]]
note: Rattrapage iOS 1.10.0 (feature 0082). GroupSetting on Android excludes picture on purpose; CoverSources has camera + photos.
created: 2026-11-09
---

## Context / Decisions

Port of iOS [0082](../wiki/features/0082-a-groups-photo-from-its-settings.md).

- **Where.** `GroupSettingsSheet` (`ui/network/groups/`) gets a first section: the group's photo in a large rounded-square slot (`GroupThumbnail`, the group's shape everywhere), or an empty slot inviting one.
- **Sources: Appareil photo + Photos only**, through `CoverSources` / `rememberCoverSources` as the edition cover (Olivier's pick). No Fichiers, no URL. With a photo set, the menu starts with « Retirer », then the sources. Picks go through `CoverPhoto.reduce` (1600 px, JPEG 80).
- **Nothing leaves the phone before « Enregistrer ».** « Enregistrer » is enabled when only the photo changed; closing the sheet uploads nothing. The form's draft: unchanged / replaced(bytes) / removed.
- **Save, server-first** (unlike the optimistic toggles): the sheet closes; `POST /api/images/upload?container=groups` → path; `PUT /api/groups/update-settings` with `attribute: picture` and that path; then the group's header and row show the new photo. « Retirer » sends `value: null`, no upload. Refused or offline → SnackBar, the group keeps its old photo; a failed upload never writes the setting.
- **Code.** `GroupSetting` gains `Picture(path: String?)` (its KDoc stops saying picture is excluded); the payload encodes `null`. The upload reuses `ApiService.upload` with the groups container; the multipart field name and the returned key are checked against inventaire.io's API (live OpenAPI or Codeberg sources), not guessed. Group stays in memory (`GroupRepository._groups`), updated from the server's answer.
- **A refused name or description** puts back only its own attribute, so it never undoes a photo that landed in the same « Enregistrer ».
- Only admins see the settings, as now. Out of scope: a photo at group creation, the group's place.

## Acceptance criteria

- As admin, Réglages du groupe opens on the photo slot: the current photo, or the empty slot.
- Tap the empty slot → menu Appareil photo, Photos. With a photo: « Retirer », Appareil photo, Photos.
- Pick a photo: the slot shows it; « Enregistrer » enabled even if nothing else changed.
- Close the sheet without saving: no request sent (unit test), the group's photo unchanged.
- « Enregistrer »: requests in order upload (`container=groups`) then `update-settings` `picture` with the returned path (unit test); the header and the group's row then show the new photo.
- « Retirer » + « Enregistrer »: `update-settings` with `value: null`, no upload; the header shows the glyph.
- Upload fails (unit test): no `update-settings` sent, SnackBar, old photo kept.
- `update-settings` refused (unit test): SnackBar, old photo kept.
- Name changed + photo replaced, name refused: the new photo stays, the name goes back.

## Implementation

- `data/groups/GroupSetting.kt`: `Picture(path: String?)` — attribute `picture`, `JsonNull` when null, `applied` sets `pictureUrl` through `ImageUrl.absolute`; `restored(on:from:)` (iOS `held(by:)`). KDoc no longer excludes picture.
- `data/groups/GroupPictureEdit.kt`: `Unchanged` / `Replaced(path)` / `Removed`, `showsPicture(savedPictureUrl)`, `isChange(from)`, `Serializable` for `rememberSaveable`.
- `data/groups/GroupPictureUpload.kt`: cached JPEG → `POST /api/images/upload?container=groups`, field `picture`, file `group.jpg`; path read back under `picture`, missing → `NetworkError.BadResponse`. Contract checked against the Codeberg server sources (`controllers/images/upload.ts` answers `{ [field]: url }`, `lib/containers.ts` allows `groups`, `models/attributes/group.ts` `picture` updatable and nullable, `update_settings.ts` `canBeNull`).
- `data/GroupRepository.kt` (305 lines): server-first `updatePicture(edit, groupId)` — Unchanged returns, Removed PUTs null without upload, Replaced uploads then PUTs; on success the picture is written onto the group as it is then, only if the account is the same; failure → `ErrorReporter`, old photo kept, a failed upload never PUTs. `update()`'s revert → `rewrite(groupId) { setting.restored(on = it, from = current) }`: a refused name no longer undoes a photo that landed. `putSetting` factored out.
- `ui/network/groups/GroupPhotoPicker.kt`: `GroupThumbnail(XLarge)` slot (96 dp; iOS 104 pt — `designsystem/Components.kt` off-limits) + « Ajouter une photo » / « Modifier la photo »; menu « Retirer la photo », « Remplacer par », « Prendre une photo », « Choisir dans la galerie » through `rememberCoverSources` / `CoverPhoto.reduce`; local preview via `file://`. `PhotoMenuLine` is a 6-line copy of `EditionFormSections`' private `MenuLine` (file edited by another branch) — share once both land.
- `GroupSettingsSheet.kt`: slot first; « Enregistrer » enabled on `textChanged || pictureChanged`; `save()` launches `container.groups.updatePicture` in `container.applicationScope` (outlives the sheet), then closes; closing sends nothing. Reaches `LocalAppContainer` as `CreateGroupSheet` does; `GroupScreen` / `GroupViewModel` unchanged.
- `strings_groups.xml`: `groups_form_picture_add`, `_change`, `_remove`; menu reuses `create_book_cover_camera`, `_photos`, `_replace`.
- Tests: `GroupPictureTest` (8, MockWebServer: upload then PUT in order with exact bodies; removal null without upload; Unchanged sends nothing; failed upload no PUT + report; refused PUT keeps photo + report; refused name while a photo lands keeps the photo — fails with the old whole-group revert; draft rules). Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest --rerun` ✅ 608 tests, 0 failures; `GroupRepositoryTest` 18 still pass.
- Runtime not run: no inventaire.io credentials; nothing uploaded.

## Review

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
