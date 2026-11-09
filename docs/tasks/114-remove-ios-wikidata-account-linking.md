---
issue: 114
status: todo
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

## Review

## Verification

## Feedback
