# Links to a book or an author, on link.exlibris.lunabee.ovh

Shipped on 2026-11-16, iOS and Android (issue #138, PR #139, first task of the « Deep links » sprint). A link
`https://link.exlibris.lunabee.ovh/entity/<uri>` opens the book or the author in Ex-libris when the app is installed,
and the same page on inventaire.io otherwise. Tested on Olivier's iPhone; Android built and unit-tested, never run on
an emulator.

## What it does

- **Which links.** One path, `/entity/<uri>`, with exactly one `isbn:`, `wd:` or `inv:` uri
  (`(isbn|wd|inv):[A-Za-z0-9-]+`). Anything else is not a link the app opens.
- **Which screen.**
  - `isbn:` → the Fiche livre of that edition, with no request.
  - Any other uri is read through `by-uris` for its type: an `edition` opens its Fiche livre, a `work` the Fiche livre
    of its best edition (as a search result does), a `human` the Auteur·ice screen.
  - Unknown entity, another type, or no network → inventaire.io's page in the browser.
- **Where.** Pushed on the Recherche tab, alone above its root; the profile sheet closes.
- **Signed out.** The link is dropped, on both platforms.
- **Without the app.** The server answers every other path with a `302` to the same path on `https://inventaire.io`,
  so the link still lands on the book.

## Technical surface

- **Server** — `scripts/deeplinks/`, on Lunabee's shared VPS (`37.59.107.30`, key `~/.ssh/exlibris_vps`):
  - `link.exlibris.lunabee.ovh.conf`: static nginx site, enabled as `sites-enabled/zz-link.exlibris.lunabee.ovh`,
    Let's Encrypt certificate from certbot (first one valid until 2027-02-13, renewed by the system timer). Its own
    subdomain, apart from the backend's `exlibris.lunabee.ovh` (#93), whose site sends every path to the backend.
  - `apple-app-site-association`: app `VH79XGK7M2.studio.lunabee.nouveau-recit`, components `/entity/*`.
  - `assetlinks.json`: `studio.lunabee.exlibris.android` (upload key and Play app signing key) and
    `studio.lunabee.exlibris.android.dev` (debug key).
  - `deploy.sh`: copies the files, asks certbot on a first run, `nginx -t` before every reload, then checks with
    `curl`. Run it again after editing any of them.
- **iOS**
  - `ReCIT-iOS.entitlements` (`applinks:link.exlibris.lunabee.ovh`), `CODE_SIGN_ENTITLEMENTS` on the app target.
    Automatic signing turned the Associated Domains capability on for the App ID at the first device build.
  - `Model/DeepLink/DeepLink.swift` parses the URL and gives `webURL`.
  - `Features/EntityBrowser/NavigationDestination+DeepLink.swift`: `init?(linkedISBN:)` and `init?(linkedEntity:)`.
  - `Features/MainNavigation/DeepLinkHandling.swift`: `onOpenURL` on `MainTabView`, the `by-uris` fetch, the
    fallback through `openURL`.
  - `TabRouter.open(_:)` sets `pendingLink`, a flag `SearchTabView.openLinkIfAsked()` consumes on appear and on
    change, like the search field request: on a cold launch the link arrives before the tab exists.
- **Android**
  - Manifest: `MainActivity` is `singleTask`, with an `intent-filter` `autoVerify` on `https://link.exlibris.lunabee.ovh/entity/`.
  - `MainActivity` puts the URL in `AppContainer.incomingLinks` (on create, not on re-creation, and in `onNewIntent`).
  - `MainScaffold` collects it, resolves through `ui/navigation/DeepLink.kt`, calls `TabRouter.openLink()` and pushes
    on Recherche's stack. `RootScreen` clears it while signed out.
- **Tests** — iOS `DeepLinkTests`, `TabRouterTests`; Android `DeepLinkTest`, `TabRouterTest`. The injection cases
  (`%7C`, `%26autocreate=true`) are among the URLs refused.

## Pitfalls

- **A decoded uri reaches a query string.** `URL.pathComponents` and `URI.path` decode `%7C` and `%26`, and
  `fetchEntities` pastes the uri into `by-uris?uris=…`: before the strict pattern, a crafted link made the signed-in
  session call `by-uris` with `autocreate=true`. Any new path that ends in a request needs the same whole-match check.
- **Safari's address bar never opens the app.** Only a link touched from another app or another domain does; on the
  simulator, `xcrun simctl openurl` works once `swcd` has fetched the file, about 30 s after the install.
- **Google re-signs the Play build**, so `assetlinks.json` names the Play app signing key (Play Console › Intégrité de
  l'app › Signature de l'app, `4E:C2…`) beside the upload key (#145). Google's statements API lists both; the first Play
  release that ships the links is still to be checked with `adb shell pm get-app-links studio.lunabee.exlibris.android`.

## Known limits

- A link under a sheet, and a link opened signed out: fixed in [0097](0097-hidden-link-opening.md).
- Other paths: `/users`, `/groups` in [0093](0093-network-deep-links.md); `/lists` in [0094](0094-list-deep-links.md); `/items`, `/shelves` in [0095](0095-inventory-deep-links.md); « Partager » in [0096](0096-share-links.md).
