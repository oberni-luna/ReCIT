---
issue: 111
status: todo
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
