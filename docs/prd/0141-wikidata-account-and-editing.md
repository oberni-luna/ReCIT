# PRD 0141 — Relier son compte Wikidata, modifier les fiches Wikidata

## Problem

« Modifier l'œuvre » d'une œuvre Wikidata ne montre que le titre, en lecture seule. inventaire.io
accepte pourtant la modification d'une entité `wd:` par `update-claim` et `update-label` : avec
les jetons Wikidata du compte s'il en a, sinon par son robot qui cite le compte.

## Solution

- Compte et connexion gagne une section « Wikidata » : relier son compte (OAuth 1.0a par
  `GET /api/auth/wikidata-oauth`, dans une `WKWebView` qui porte la session), ou voir qu'il est
  relié et gérer l'accès chez Wikimedia. `enabledOAuth` de `GET /api/user` dit lequel.
- Les œuvres et personnes `wd:` s'ouvrent dans « Modifier l'œuvre » / « Modifier l'auteur·ice »
  comme les `inv:`, avec une note qui dit qui signe la modification. Leurs propriétés ne nomment
  que des entités Wikidata.

## Modules

- `WikidataOAuthFlow` (pur) : URL de départ, reconnaissance du retour.
- `AccountSettings.linksWikidata`, `UserDTO.enabledOAuth`.
- `AuthService.webSessionCookies()` / `AuthModel.webSessionCookies()`.
- `WikidataConnectSheet`, `WikidataWebView`, `AccountWikidataSection`.
- `EntityEdit.canEdit(uri:)`, `EntityPickerView(wikidataOnly:)`, `WikidataEditNotice`.

## Tests

Swift Testing sur les modules purs : `WikidataOAuthFlow`, `AccountSettings(userDTO:)`,
`EntityEdit.canEdit(uri:)`, le filtre du sélecteur.

## Out of scope

Les éditions Wikidata ; délier le compte depuis l'app ; Android.
