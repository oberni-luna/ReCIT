---
issue: 111
status: to-close
wiki: [[features/0055-profile-editing]], [[features/0041-android-catches-up-with-ios]], [[features/0031-android-app]]
note: "Je voudrais ajouter les fonctionnalités d'édition du profil aussi dans ce sprint Android" — split into #111 (profil), #112 (compte et connexion), #113 (notifications).
created: 2026-11-09
---

## Context / Decisions

> Je voudrais ajouter les fonctionnalités d'édition du profil aussi dans ce sprint Android

Port of the « Modifier le profil » third of iOS [0055](../wiki/features/0055-profile-editing.md). #112 and #113 port the other two screens and build on this one.

- **Entry.** The Profil (`ui/profile/ProfileScreen.kt`, inside `ProfileSheet`'s own stack) gets « Modifier le profil » under the account's header, pushing a new destination. My bio shows under my name in the Profil's header.
- **Form** (one screen, « Enregistrer » pinned at the foot, enabled when something changed):
  - **Picture**: Appareil photo, Galerie (`rememberCoverSources` + `CoverPhoto.reduce`), **the account's Gravatar** (`GET /api/images/gravatar`, then the image downloaded without cookies and sent like a photo; absent on `404`), « Retirer ».
  - **Username**, checked while typed as at sign-up (`FieldAvailability`, `auth/`).
  - **Bio**, counted against 1 000 characters.
  - **Position**: a row opening the position screen, « Retirer ma position ».
- **Position screen: osmdroid (OpenStreetMap)** — new dependency, approved by Olivier: no API key, no Google services, so it works on no-GMS phones (#42). The pin stays in the middle while the map moves; a search moves the map to a place (`android.location.Geocoder` when `Geocoder.isPresent()`, else the search field is hidden); « Valider » hands the centre back to the form, **rounded to two decimals** before it leaves the phone. osmdroid's tile user agent set to the app's id (OSM tile policy).
- **Save, server first, one attribute per request** (`PUT /api/user` takes `{ attribute, value }` only): picture uploaded to `container=users` first, then one PUT per changed attribute in the order picture, username, bio, position; each written onto my `UserEntity` as it lands. A refusal part of the way keeps what landed, a banner names the refused attribute, the next « Enregistrer » sends only the rest.
- **`RequestPacer`**: every `PUT /api/user` waits 1.1 s after the previous one (server `minTimeBetweenRequests: 1000`). Lives in the data layer, shared with #112 and #113.
- **Pure `ProfileDraft`** (changed attributes in order, validation, rounding, `markLanded`) and a `UserAttributeUpdate` body with an explicit `null`, unit-tested.
- Multipart field name / response key for `container=users` and the Gravatar endpoint checked against inventaire.io's live OpenAPI or Codeberg sources, never guessed.
- Strings French only; copy as iOS. Out of scope: « Utiliser ma position actuelle » (location permission), place name under the map, Wikidata.

## Acceptance criteria

- Profil: « Modifier le profil » under the header; my bio shows under my name.
- The form opens with my picture, username, bio, position.
- Typing a taken username: the sign-up availability message; « Enregistrer » disabled while invalid.
- Bio past 1 000 characters: counter shows it and « Enregistrer » is disabled.
- Picture menu: Appareil photo, Galerie, Gravatar, Retirer; Gravatar shows the account's image or says there is none.
- Position: the map (OpenStreetMap) with a centred pin; moving it and « Valider » shows the position in the form; « Retirer ma position » clears it.
- « Enregistrer » with picture + bio changed: upload then two PUTs, ≥ 1 s apart, in order (unit test); the Profil header shows the new picture and bio.
- Second PUT refused (unit test): first change kept, banner names the refused attribute, next save sends only it.
- Position sent with two decimals (unit test).
- Works on the NoGMS_API_35 emulator (map shows, search hidden if no geocoder).

## Implementation

- New `data/user/`: `RequestPacer` (Mutex; each call waits for the previous one, then 1.1 s after its start — singleton `container.userUpdatePacer`), `UserAttributeUpdate` (`value: JsonElement` so `JsonNull` is sent as `"value":null` despite `explicitNulls = false`), `Coordinates`, `ProfileChange`, `ProfileDraft` (changed attributes in order picture, username, bio, position; bio ≤ 1 000 UTF-16 units; position rounded to 2 decimals; `markLanded`), `ProfileSaveFailure` (`isUsernameTaken` reads « already used »), `MyProfileStore` (implemented by `UserRepository.updateMyUser`), `ProfileRepository` (upload `container=users` field `avatar`, then one paced `PUT /api/user` per change, each written onto my `UserEntity`; Gravatar `GET /api/images/gravatar` then image through `publicClient`, none on 404). #112 / #113 call `container.profile.updateUserAttribute(...)`.
- New `ui/profile/edit/`: `EditProfileScreen` + `EditProfileViewModel` + `EditProfileUiState`, `ProfilePhotoPicker` (Appareil photo, « Choisir dans la galerie », Gravatar, Retirer; `CoverPhoto.reduce(bytes)` overload added), `ProfileBioField`, `ProfilePositionSection`, `ProfilePositionScreen` (a state of the form's ViewModel, not a Destination — the draft must not outlive the form, as `EditEditionPage`), `PositionMap` (osmdroid in `AndroidView`, fixed above the list; zoom 13 around a position, 6 on France without), `OsmConfiguration` (user agent = application id, cache under `cacheDir/osmdroid`), `PlaceSearch` / `FoundPlace` (`Geocoder` when present; `GeocodeListener` API 33+, else sync on IO; 5 results). « Retirer ma position » on the form and on the position page.
- osmdroid-android 6.1.20 (libs.versions.toml, app/build.gradle.kts); `ACCESS_NETWORK_STATE` in the manifest (osmdroid requirement, normal permission). OSM attribution « © les contributeur·ices d'OpenStreetMap » at the map's corner (new copy, tile policy).
- `Destination.EditProfile` + entry; `ProfileScreen`: « Modifier le profil » under the header, my bio under the counts. `EditionFormSections.MenuLine` private → internal for the photo menu. `UserDtos.GravatarDto`. Strings in `strings_profile.xml` (iOS copy, « vous »).
- API contracts verified 2026-11-09 against Codeberg `inventaire/inventaire` main and live `api_specs.json` v5.1.1: upload answers `{ field: url }`, `/img/users/<40 hex>`; gravatar `{ url }` with `d=404`; `PUT /api/user` `{ attribute, value }`, `acceptNullValue` position + picture, position `[lat, lng]`, bio `BoundedString(0, 1000)`, `minTimeBetweenRequests: 1000`, unchanged value → `400 already up-to-date`.
- Tests: `ProfileDraftTest` (12), `ProfileRepositoryTest` (6: order upload → PUT picture → PUT bio, ≥ 1 000 ms apart in virtual time, each written onto my user, partial failure, retry), `RequestPacerTest` (4), `UserAttributeUpdateTest` (3). Build: `./gradlew :app:assembleDebug :app:testDebugUnitTest` ✅ 625 tests, 0 failures.
- Known gap (out of scope): `Merges.user` never clears `avatarUrl` / position when a sync payload lacks them — a removal made on another device does not reach this one.
- Runtime not run: no inventaire.io credentials; nothing written.

## Review

### Round validation — 2026-11-10

- Scope: `origin/sprint/android-1-4-0...wa/111-add-android-profile-editing`.
- Findings (all 🟡 minor), fixed by autofix in two rounds, re-verified clean:
  - [correctness] Picking the same place twice didn't move the map back: the move is keyed on a `moves` counter, not on state equality.
  - [correctness] Rotation snapped the map back and « Valider » returned the old position: `center` and `zoom` are `rememberSaveable`; a pinch-zoom is still not restored (cosmetic).
  - [correctness] Any non-200 from gravatar.com read as « pas de photo Gravatar »: only 404 is « none », other codes throw `NetworkError.BadStatus` (test on 503).
  - [elegance] A picture gone from the cache was a network error: `MissingPictureFile`, read through the new `data/CachedPicture` (round 2 — `CoverPhoto.bytes` delegates to it, no data→ui import).
  - [structure] `DestructiveRow` in its own file.
  - [style] `val observer: LifecycleEventObserver`.
- Final: `LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓` — clean. Build ✅, 627 tests, 0 failures.
- ⚠️ Code changed since the user's test: the position map (search pick, rotation) and the Gravatar error message.
- Wiki: nothing task-specific; the sprint's feature doc is written with #101.
- Screenshots: none — `verify.platform: ios`, this task is Android.

- Landing — rebased onto `sprint/android-1-4-0` after #99: #99 had moved `MenuLine` into `ImageSourceMenu.kt`; the copy in `EditionFormSections.kt` dropped and `ImageSourceMenu`'s `MenuLine` made `internal` for the profile photo's menu (it has a Gravatar line, so not `ImageSourceMenu` itself). Build ✅, 672 tests, 0 failures.

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
