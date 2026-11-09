---
issue: 99
status: todo
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
