# Linking a Wikidata account, and editing Wikidata works and authors

Shipped on 2026-11-01, on `main`, in an autopilot run of two slices (PRD 0141, issues 0141 and 0142, deleted
since). Mock-ups: Figma `S7IvC6GvlcUFe5IgbtvQq6`, page `Profil`, third row of « Edition de profil »
(`800:3908`): `W1 · Compte et connexion · Wikidata non relié` (`906:1379`), `W2 · Connexion à Wikidata · page
web` (`906:1833`), `W3 · Compte et connexion · Wikidata relié` (`906:1486`), `W4` (`906:1641`), `W5`
(`906:1652`) and the `Spec · Wikidata` panel (`907:3088`). It opens to Wikidata what
[0057](0057-edit-works-and-authors.md) did for inventaire.io's own works and people.

## What it does

- **A Wikidata work or person opens in « Modifier l'œuvre » / « Modifier l'auteur·ice »**, the whole screen of
  0057, like one of inventaire.io's. Before, a Wikidata work showed its title read-only and a Wikidata author
  had no chevron.
- **A line at the head of the screen** says that « Enregistrer » publishes on Wikidata, and under whose name:
  - the reader's Wikidata account once it is linked;
  - otherwise inventaire.io's bot, which names the reader's account, with where to link it.
- **Its properties name Wikidata entities only.** inventaire.io refuses to link a Wikidata entity to one of its
  own (« wikidata entities can't link to inventaire entities »). The picker of a Wikidata work or person
  therefore shows Wikidata's results alone and offers no « Créer ». With no Wikidata result, its footer says to
  create the missing entry on wikidata.org.
- **« Compte et connexion » ends on a « Wikidata » section.**
  - Not linked: « Relier mon compte Wikidata » opens wikidata.org in a sheet titled « Wikidata ».
  - Linked: « Compte Wikidata · Relié », and « Gérer l'accès sur Wikimedia », which opens
    `Special:OAuthManageMyGrants`.
  - The footer says who signs an edit.
- **The sheet** shows Wikimedia's own pages: sign in to Wikimedia if needed, allow inventaire.io. It closes by
  itself when the server sends the browser back, or with its cross. The account is read again either way, and a
  SnackBar says « Compte Wikidata relié » when it is.

## Technical surface

- **What the server does**, read on inventaire.io's source (Codeberg, `server/controllers/entities/`):
  - `update-claim` and `update-label` take `wd:` uris and hand them to `updateWdClaim` / `updateWdLabel`;
  - `getWikidataEditReqConfig` signs with the account's tokens (`user.oauth.wikidata`) when it has some, and
    otherwise with inventaire.io's bot account, with `Edit on behalf of acct:<user>` in the summary;
  - so **no Wikidata account is needed to edit**: linking changes who signs.
- **Linking** is `GET /api/auth/wikidata-oauth?redirect=/settings/account`: OAuth 1.0a in three legs, all
  redirects. The server stores the tokens and sends the browser to `https://inventaire.io/settings/account`.
  - `WikidataOAuthFlow` (pure, `Model/Authentication/`) holds the start address, the return address and the
    grants page.
  - `WikidataWebView` is a `WKWebView` in a `UIViewRepresentable`. SwiftUI's `WebView` starts at iOS 26.
  - It gets the session cookies from `AuthModel.webSessionCookies()` → `AuthService.webSessionCookies()`. The
    first leg is refused to a request that names nobody.
  - It keeps them in a `.nonPersistent()` website data store, so nothing it is sent reaches the app's jar
    (ADR 0008).
  - It cancels the navigation to the return address, reports once, and loads nothing more.
- **Whether it is linked**: `GET /api/user` serves `enabledOAuth` to the owner (`ownerSafeData`). `UserDTO`
  reads it, and `AccountSettings.linksWikidata` holds it. Nothing new is stored.
- **Editing**: one rule, `EntityEdit.canEdit(uri:)`, says that `inv:` and `wd:` open for editing. It is used by
  `EntityEdit.isEditable`, by the route to a work's screen (`EditEditionFlowView.openWork`), by an author's
  chevron (`EditEntityPersonRow`) and by a list of people (`EditionEntityValuesView`).
  - `EntityEdit.linksWikidataOnly(uri:)` goes through `EditionPropertyDestination(wikidataOnly:)` to
    `EntityPickerView(wikidataOnly:)`, whose static `candidates(_:wikidataOnly:)` filters the results.
  - `WikidataEditNotice` is the line at the head of `EditEntityView`.
- **The save is unchanged**: the same `update-claim` and `update-label` calls, on the `wd:` uri, with the same
  failure banner when Wikidata refuses.
- Thirteen strings, `account.wikidata.*`, `edit_entity.wikidata.*` and `entity_picker.wikidata_only*`, in
  English and French.

## Decisions

- **Everyone can edit, linked or not.** The mock-up gated editing on a linked account (`W4`'s notice). The
  server's bot fallback was found during the run, and the user chose to open editing to everyone, with linking
  for signing one's own edits. `W4` is not built.
- **A web view, not `ASWebAuthenticationSession`**: the latter does not share the app's session, and the server's
  last redirect goes to a page of the website, not to a scheme of the app.
- **The return address is a page the web view never loads**: reaching it is the signal.
- **No unlinking in the app**: inventaire.io has no endpoint for it. Taking the access back at Wikimedia makes
  the tokens invalid, but `enabledOAuth` still lists `wikidata`.

## Tests

- `WikidataAccountTests`: the start address, the return address (and not the legs on wikidata.org), and
  `enabledOAuth` read as linked or not.
- `WikidataEntityEditingTests`: `canEdit`, `linksWikidataOnly`, the picker's filter, and a Wikidata work's label
  sent on its `wd:` uri.

## Not done, not verified

- **Never run against inventaire.io**: no account was linked, and no Wikidata edit was made. A real link needs a
  Wikimedia account. This run types no passwords.
- **Not seen on a simulator**: the section, the sheet and the notice were built, not looked at.
- **Revoked tokens**: after the access is taken back at Wikimedia, an edit fails with whatever Wikidata
  answers, in the generic failure banner. The app does not send the reader back to link again.
- **Wikidata editions** stay read-only (`EditionClaims.canEdit`).
- **`EditWorkView`** still carries the Wikidata footer (`edit_work.wikidata_help`) for a work it no longer
  receives.
- **Dark mode of the sheet** is Wikimedia's own. Figma `W2` is light only.
- **Android** not ported.
- **e2e not run.**
