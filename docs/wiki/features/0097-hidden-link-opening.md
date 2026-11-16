# A link opens signed out, and over any sheet

Shipped on 2026-11-16, iOS and Android (issue #143, PR #151, last task of the « Deep links » sprint, after
[0092](0092-entity-deep-links.md)–[0096](0096-share-links.md)). Two cases where an Ex-libris link seemed to do nothing:
the app is signed out, or a modal hides the tab the link pushes on. Every link of 0092–0095 now opens in both. Seen on
the simulator with the Profil sheet up; the signed-out flow never run (the simulator account must stay signed in);
Android built and unit-tested, never run on an emulator.

## What it does

- **Signed out, the link waits.** Kept in memory, not on disk: a link that dies with the app is opened again from
  where it was. A newer link replaces a waiting one.
  - The welcome screen shows « Connectez-vous pour ouvrir ce lien. » (en « Sign in to open this link. ») under its
    buttons while a link waits; the screen still says « vous ».
  - The link opens once the session is up **and my user is known** (`syncMyUser` returned), after a sign-in, a
    sign-up or a cold launch alike: before that, my own username or étagère would read as a stranger's.
  - A session the server refuses on a cold launch keeps the link for the next sign-in.
- **A modal is up, the link opens in a sheet over it.** Any sheet or cover (a form, the request sheet, « Ranger mes
  livres », the Profil): it stays as it was underneath, nothing typed is lost. The link sheet holds its own stack with
  the link's screen at its root and « Fermer »; further pushes stay inside it. No modal → the push on the link's tab,
  as before. If no sheet can be shown (the Profil mid swipe-down), the push on the tab.
  - My own username opens the Profil; inside the link sheet when another modal is up; nothing when the Profil is up.
- **A URL on the link domain the app cannot read** (`/users/a%7Cb`, `/users/x/inventory`) opens the same path on
  inventaire.io at once, signed in or out, never waits — the server's own `302`.

## Technical surface

- **iOS**
  - `TabRouter` is owned by `RootView` (a sign-out builds a fresh one, carrying the waiting link):
    `waitingLink`, `receive(_:isMyUserKnown:)`, `takeWaitingLink()`, `open(_:on:isModalUp:) -> LinkSheetContent?`,
    `openWithoutSheet(_:)`.
  - `DeepLinkHandling` sits on `RootView`, around both branches; `.onChange(of: userModel.myUser?._id)` opens the
    waiting link. `DeepLink.inventaireURL(for:)` rewrites a refused URL.
  - `LinkSheetPresenter`: **the one UIKit type** (CLAUDE.md's exception): walks the key window's `presentedViewController`
    chain, presents a `UIHostingController` page sheet over the topmost, reports whether it could. `LinkSheet`,
    `LinkSheetContent`.
  - `AppEnvironment`: one modifier with every shared model, the router, `syncUserData`, the model context and the
    tint, used by `RootView` and by the link sheet, so a model added later reaches both. `ownsShelfFocus()` gives the
    Profil and the link sheet their own shelf focus.
  - `WelcomeLinkWaitingLine`. Developer-mode entitlement `applinks:…?mode=developer` beside the normal one.
- **Android**
  - `ui/navigation/IncomingLinks`: `receive(url)`, `waiting`, `toOpen(myUserId)` (waits for my user id, clears with
    `compareAndSet` so a newer link wins). `MainActivity.receive` ignores intents without data (the launcher's MAIN
    intent under `singleTask`) and sends a refused URL straight to the browser.
  - `TabRouter.openLink(target): LinkLanding?` → `OnTab`, `InDialog` or nothing; covered = the Profil presented or an
    overlay declared with `CoversTabs()`.
  - `ui/root/LinkDialog.kt`: full-screen `Dialog` with its own Nav3 back stack; `LocalStackClose` turns the root's back
    arrow into « Fermer »; kept across rotation (`rememberSaveable`, `LinkTarget` `@Serializable`).
- **Tests** — `TabRouterTests`, `DeepLinkTests`; Android `IncomingLinksTest`, `TabRouterTest`, `DeepLinkTest`.

## Pitfalls

- **Every Android overlay must call `CoversTabs()`**, or a link pushes beneath it.
- **The link sheet is UIKit-presented**: SwiftUI's `dismiss()` inside it was assumed, then seen working (« Fermer »).
  Keep any change to presentation inside `LinkSheetPresenter`.

## Known limits

- A link kept across an app kill is not.
- An offline cold launch keeps the link waiting until a sync succeeds.
- « Modifier l'édition » and « Ranger mes livres » under a link never seen.
