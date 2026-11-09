---
issue: 114
status: to-test
wiki: [[features/0070-wikidata-account-and-editing]], [[adr/0008-session-login-signup-keychain]]
note: enlever la connexion WikiData qui ne fonctionne pas sur iOS
created: 2026-11-09
---

## Context / Decisions

> enlever la connexion WikiData qui ne fonctionne pas sur iOS

- Linking a Wikidata account from iOS (0070) does not work. It goes away from the app.
- Scope = the link only. Editing Wikidata works and people stays: without a linked account,
  inventaire.io's bot publishes the edit and names the reader's account (0070 → Decisions).
- Removed:
  - the « Wikidata » section at the foot of « Compte et connexion » (`AccountWikidataSection`, the
    `AccountWikidataSection(isLinked:)` call in `AccountSettingsView`);
  - `WikidataConnectSheet` and `WikidataWebView`;
  - in `WikidataOAuthFlow`: `startURL`, `isReturn`, `manageGrantsURL`. Only `provider` stays, read by
    `AccountSettings`;
  - `AuthModel.webSessionCookies()` and `AuthService.webSessionCookies()`: only `WikidataWebView` used them;
  - the `account.wikidata.*` strings, in English and French;
  - the tests of the start and return addresses in `WikidataAccountTests`.
- Kept: `UserDTO.enabledOAuth` → `AccountSettings.linksWikidata`. An account linked from the inventaire.io
  website still signs its own edits, so the notice's linked variant stays true.
- `WikidataEditNotice`: both variants stay. `edit_entity.wikidata.bot` loses its last sentence (« Reliez votre
  compte Wikidata dans Compte et connexion pour les publier sous votre nom. »), in French and English, because
  that section no longer exists.
- `.swiftlint.baseline` entries of the deleted files go with them; the baseline only shrinks.
- Android: never ported (0070 → Not done), nothing to do.
- At close, the 0070 feature doc and its `CLAUDE.md` line say the link was removed.

## Acceptance criteria

- « Compte et connexion » ends without any « Wikidata » section: no « Relier mon compte Wikidata », no
  « Gérer l'accès sur Wikimedia ».
- A Wikidata work or person still opens in « Modifier l'œuvre » / « Modifier l'auteur·ice ».
- Not linked: the notice at the head of that screen reads « Cette fiche vit sur Wikidata : « Enregistrer » y
  publie vos modifications par le robot d'inventaire.io, qui cite votre compte. », and nothing more.
- Linked (`enabledOAuth` contains `wikidata`): the notice still reads « … sous votre nom Wikidata. ».
- No `account.wikidata.*` key left in `Localizable.xcstrings`.
- `WikidataConnectSheet`, `WikidataWebView` and `webSessionCookies` return zero hits in the code.
- The build passes with SwiftLint; `WikidataAccountTests` and `WikidataEntityEditingTests` pass.

## Implementation

- Deleted `AccountWikidataSection`, `WikidataConnectSheet`, `WikidataWebView` (synchronized group: no
  `project.pbxproj` change).
- `AccountSettingsView`: the Wikidata section call and its header mention removed.
- `WikidataOAuthFlow`: only `provider` left; header says linking happens on the inventaire.io website.
- `AuthModel.webSessionCookies()` and `AuthService.webSessionCookies()` deleted; the private `sessionCookies()`
  stays (4 other callers).
- `WikidataAccountTests`: `startURL`, `returnAddress` and `baseURL` deleted; `linked` / `notLinked` kept.
- `WikidataEditNotice`: header comment only.
- `Localizable.xcstrings`: 9 `account.wikidata.*` keys removed; `edit_entity.wikidata.bot` loses its last
  sentence in fr and en. No other key touched.
- `.swiftlint.baseline`: 4180 → 4154 entries — 22 for the deleted files, 4 made stale (`manageGrantsURL` and
  test `baseURL` force unwraps, two deleted test names). The two `AuthService` length entries rewritten with the
  lower counts (512 lines, body 259): SwiftLint matches by reason, which carries the count. Ceilings only went
  down.
- Build: `** BUILD SUCCEEDED **` (ReCIT_iOS, iPhone 17, SwiftLint in the build).
- Tests: `** TEST SUCCEEDED **` — `WikidataAccountTests` (2) and `WikidataEntityEditingTests` (4).

## Review

## Verification

manual validation — not run by agent

## Feedback
