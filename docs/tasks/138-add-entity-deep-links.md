---
issue: 138
status: to-close
wiki: [[features/0037-search-tab]], [[features/0031-android-app]]
note: First slice of #65 (Add deep links), which builds on it for the other paths, the backend page and « Partager ». Written and deployed on 2026-11-15 before the grill, left uncommitted in the main checkout of sprint/ios-perf-test; /wa-code carries those files over to this branch. The server part is already live.
created: 2026-11-15
---

## Context / Decisions

> Deep links Ex-libris : https://link.exlibris.lunabee.ovh/entity/<uri> ouvre le livre / l'œuvre / l'auteur·ice dans l'app (iOS universal link, Android App Link), et redirige vers https://inventaire.io/entity/<uri> quand l'app n'est pas installée.

A link `https://link.exlibris.lunabee.ovh/entity/<uri>` opens the book or the author in Ex-libris when the app is installed, and the same page on inventaire.io otherwise.

1. **First slice of #65.** Only `/entity/<uri>`, with no backend involved. #65 adds `/items`, `/users`, `/shelves`, `/lists`, the backend page shown when the app is missing, the link kept through sign-in, « Partager », and the final choice of domain.
2. **Domain: `link.exlibris.lunabee.ovh`**, its own subdomain. `exlibris.lunabee.ovh` belongs to the backend (#93), whose nginx site sends every path to the backend, and `deploy-backend.sh --setup` would overwrite a site edited by hand. The `*.lunabee.ovh` wildcard already points at the VPS.
3. **The server is static** (`scripts/deeplinks/`), on the shared OVH VPS `37.59.107.30`:
   - `link.exlibris.lunabee.ovh.conf`: nginx site, installed as `sites-available/link.exlibris.lunabee.ovh` and enabled as `sites-enabled/zz-link.exlibris.lunabee.ovh`, Let's Encrypt certificate from certbot.
   - `apple-app-site-association`: app `VH79XGK7M2.studio.lunabee.nouveau-recit`, path `/entity/*`.
   - `assetlinks.json`: `studio.lunabee.exlibris.android` (upload key, and the Play app signing key once added) and `studio.lunabee.exlibris.android.dev` (debug key).
   - Every other path gets a `302` to the same path on `https://inventaire.io`. HTTP gets a `301` to HTTPS.
   - `deploy.sh`: copies the three files, asks certbot on the first run, runs `nginx -t` before every reload, then checks the result with `curl`.
4. **The path is inventaire.io's own**, so the fallback is the same path with another host.
5. **Which screen.** An `isbn:` uri is an edition by construction and opens its Fiche livre with no request. Any other uri is read through `by-uris` to get its type:
   - `edition` → Fiche livre of that edition;
   - `work` → Fiche livre of its best edition, as a search result does;
   - `human` → Auteur·ice;
   - anything else, an unknown entity, or no network → inventaire.io's page in the browser.
6. **Where the screen opens: on Recherche**, the one stack tied to no place in the app, alone above its root. The profile sheet closes.
7. **Signed out**: the link is dropped. Keeping it through sign-in is #65.
8. **iOS**:
   - `ReCIT-iOS.entitlements`: `applinks:link.exlibris.lunabee.ovh`, set on the app target in Debug and Release.
   - `Model/DeepLink/DeepLink.swift`: parses the URL and gives the inventaire.io fallback.
   - `Features/EntityBrowser/NavigationDestination+DeepLink.swift`: picks the screen (`init?(linkedISBN:)`, `init?(linkedEntity:)`); `DeepLinkHandling` fetches the entity.
   - `Features/MainNavigation/DeepLinkHandling.swift`: `onOpenURL`, applied on `MainTabView`.
   - `TabRouter.open(_:)` / `pendingLink`, read by `SearchTabView` like the search field request: on a cold launch the link arrives before the tab exists.
9. **Android**:
   - Manifest: an `intent-filter` with `autoVerify` on `https://link.exlibris.lunabee.ovh/entity/`. `MainActivity` becomes `singleTask` and takes later links through `onNewIntent`.
   - `ui/navigation/DeepLink.kt`: the same rules as iOS.
   - `AppContainer.incomingLinks`: keeps the link until the shell exists.
   - `MainScaffold` pushes the screen on Recherche after `TabRouter.openLink()`.
10. **Play app signing key**: part of this task. Google re-signs the Play build, so its links stay unverified until `assetlinks.json` carries that key's SHA-256 (Play Console › Intégrité de l'app › Signature de l'app). Olivier gives the fingerprint, then `scripts/deeplinks/deploy.sh` publishes it.
11. **Associated Domains capability**: Xcode's automatic signing turns it on for the App ID at the first device build. Nothing to commit.

### Out of scope

- The other paths, the backend page, « Partager », keeping a link through sign-in: #65.
- An `inventaire.io` link opening the app. The domain is not ours.

## Acceptance criteria

- `curl -i https://link.exlibris.lunabee.ovh/.well-known/apple-app-site-association` and `…/.well-known/assetlinks.json` → `200`, `application/json`, no redirect.
- `curl -i https://link.exlibris.lunabee.ovh/entity/wd:Q535` → `302` to `https://inventaire.io/entity/wd:Q535`.
- `curl -i http://link.exlibris.lunabee.ovh/entity/wd:Q535` → `301` to the HTTPS address.
- iOS, signed in, the link tapped from another app (Safari page, Notes):
  - `…/entity/isbn:9782070360024` → Recherche, Fiche livre of *L'étranger*;
  - `…/entity/wd:Q535` → Recherche, Auteur·ice Victor Hugo;
  - a work uri → Recherche, Fiche livre of its best edition;
  - `…/entity/inv:0000000000000000` → Safari, on the same page on inventaire.io.
- iOS, the profile sheet up when a link arrives → the sheet closes and the screen shows.
- Android emulator, `adb shell am start -a android.intent.action.VIEW -d <link>` with the same four links → the same results.
- Android emulator, `adb shell pm get-app-links studio.lunabee.exlibris.android.dev` → `link.exlibris.lunabee.ovh: verified`.
- Google's statements API for `https://link.exlibris.lunabee.ovh` lists `studio.lunabee.exlibris.android` with the Play app signing key's fingerprint.
- `DeepLinkTests` (iOS) and `DeepLinkTest` (Android) pass.

## Implementation

- Written before the grill on top of `sprint/ios-perf-test`, carried over uncommitted to this branch (none of its files differ from `main`).
- Server: `scripts/deeplinks/` (nginx site, `apple-app-site-association`, `assetlinks.json`, `deploy.sh`), live on the VPS since 2026-11-15, certificate valid until 2027-02-13. Google's statements API and Apple's CDN both read the files.
- iOS:
  - `ReCIT-iOS.entitlements`, `CODE_SIGN_ENTITLEMENTS` on the app target (Debug, Release).
  - `Model/DeepLink/DeepLink.swift`: `DeepLink` (`Sendable`), `init?(url:)` accepting only `(isbn|wd|inv):[A-Za-z0-9-]+`, `webURL`.
  - `Features/EntityBrowser/NavigationDestination+DeepLink.swift`: `init?(linkedISBN:)` (no request) and `init?(linkedEntity:)` (by type); the `by-uris` fetch sits in `DeepLinkHandling`.
  - `Features/MainNavigation/DeepLinkHandling.swift`: `ViewModifier`, `onOpenURL`, applied in `MainTabView`.
  - `TabRouter.pendingLink` / `open(_:)` / `consumePendingLink()`, read by `SearchTabView.openLinkIfAsked()` on appear and on change.
- Android:
  - Manifest: `singleTask`, `intent-filter` with `autoVerify` on `/entity/`.
  - `ui/navigation/DeepLink.kt` (same uri pattern), `TabRouter.openLink()`.
  - `AppContainer.incomingLinks`, set by `MainActivity` (create, not re-creation, and `onNewIntent`), consumed by `MainScaffold`.
  - `RootScreen`: signed out, a waiting or arriving link is cleared (decision 7).
- Implementer pass: header prose moved to doc comments, `case let` patterns, `Sendable`, view member order; no behaviour change.
- Tests: iOS `DeepLinkTests` 5/5, `TabRouterTests` 11/11 (2 new for `open` / `consumePendingLink`); Android `DeepLinkTest` 4/4, `TabRouterTest` 8/8, `assembleDebug` green. SwiftLint clean.
- Notes:
  - CLAUDE.md says no type on `@Environment`; SwiftLint `explicit_type_interface` requires it on new code. Kept the types.
  - New iOS tests use backtick names (`test_name_backticks`), older ones in `TabRouterTests` keep the string style.
  - `:app:lintDebug` has 12 errors that predate this task, none in its files.

## Review

### Round validation (2026-11-16)

Round 1, 7 findings, autofixed:
- 🟠 [correctness] `DeepLink.swift`: the uri was only checked for `:`. `pathComponents` decodes `%7C` and `%26`, and `fetchEntities` pastes the uri raw into `by-uris?uris=…`, so `/entity/wd:Q1%7Cisbn:…%26autocreate=true` made the signed-in session autocreate on inventaire.io. → only `(isbn|wd|inv):[A-Za-z0-9-]+`, injection cases tested.
- 🟡 [correctness] `DeepLink.kt`: same loose check (`|` fetched two entities, one picked at random) → same pattern and tests.
- 🟡 [correctness] `MainScaffold.kt`: `runCatching` swallowed `CancellationException` and opened the browser → rethrown.
- 🟡 [structure] `AppModels/` returned `NavigationDestination` → mapping moved to `Features/EntityBrowser/NavigationDestination+DeepLink.swift`, `EntityModel+DeepLink.swift` deleted.
- 🟡 [style] test helper → `EntityResultDTO.mock(…)` in the model file.
- 🟡 [structure] Android `openLink` test → `TabRouterTest.kt`.
- 🟡 [correctness] accepted, not fixed: `TabRouter.open` / `openLink` close only the profile sheet; a link arriving under another sheet or cover pushes beneath it. Known limit, for #65.

Round 2, 2 findings, fixed: stale references to `EntityModel+DeepLink` in `DeepLink.kt`'s KDoc and in this file.

## Verification

manual validation — not run by agent

- Before the grill, on the iPhone 17 simulator, signed in, links tapped from Safari: `isbn:9782070360024` → Recherche, Fiche livre of *L'étranger*; `wd:Q535` → Recherche, Auteur·ice Victor Hugo.
- `curl` checks of the server criteria: AASA and assetlinks `200 application/json`, `/entity/…` → `302` inventaire.io, HTTP → `301`.
- Still owed: work uri, unknown uri, profile sheet up, Android emulator, Play app signing key.

## Feedback
