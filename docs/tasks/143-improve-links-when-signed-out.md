---
issue: 143
status: to-test
wiki: [[features/0092-entity-deep-links]], [[features/0011-ex-libris-pre-login-onboarding]], [[features/0038-profile-behind-the-avatar]], [[architecture]]
note: Fifth task of the « Deep links » sprint. Comes after #140, #141 and #142, which add the other links and the per-tab push; it changes the same files (TabRouter, DeepLinkHandling, MainScaffold). Split from #65, plus the limit accepted in #138's review.
created: 2026-11-16
---

## Context / Decisions

> Aujourd'hui (#138) un lien ouvert déconnecté est perdu, et un lien reçu sous une sheet ou une fullScreenCover ouverte se pousse dessous (accepté en revue de #138). Garder le lien pendant la connexion puis l'ouvrir ; fermer ce qui le cache. iOS et Android. Issu de #65.

Two cases where an Ex-libris link seems to do nothing today: the app is signed out, or a modal hides the tab the link pushes on. After this task, every link of #138, #140, #141 and #142 opens in both cases.

1. **Signed out: the link waits for sign-in.**
   - The link is kept in memory, not on disk: a link that dies with the app is opened again from where it was.
   - It opens right after signing in or signing up, with the same rules as a signed-in link. Before the first sync ends, a friend's copy may not be in the store yet and opens as a stranger's (#142): accepted.
   - A second link while signed out replaces the first.
2. **The welcome screen says it**: one line under its buttons while a link waits, along the lines of « Connecte-toi pour ouvrir ce lien. ». Same person as the rest of the screen (`wording.md`: a screen still in « vous » stays in « vous »). Gone once the link opens.
3. **A modal is up: the link opens in a sheet over it.**
   - Any modal: a form's sheet, the request sheet, « Ranger mes livres »'s cover, the Profil sheet. The modal stays as it was underneath, nothing typed is lost.
   - The sheet holds its own navigation stack with the link's screen at its root, and « Fermer ». Further pushes inside it stay in it.
   - No modal up → the push on the link's tab, as today.
   - **The Profil sheet is a modal like the others**: #138 and #140 close it; now the link sheet goes over it. My own username (#140) still opens the Profil sheet itself, unless it is already up.
4. **iOS: presented through UIKit**, from the topmost `presentedViewController`, as a `UIHostingController`. SwiftUI cannot present over a modal another view owns; this is the one exception to « no UIKit » (CLAUDE.md), and it stays inside one type in `Features/MainNavigation/`.
   - The sheet gets the same environment as `MainTabView`: every shared model, the router, the snack bar, the model container. One modifier injects them, used by `RootView` and by the link sheet, so a model added later reaches both.
5. **Android: a full-screen `Dialog`** with its own back stack, shown over any bottom sheet or overlay (Profil, « Ranger mes livres »). No overlay → the push on the tab, as today.
6. **Where it lives**: the waiting link and the « modal up? » decision in `TabRouter` (iOS) / `TabRouter` + `AppContainer.incomingLinks` (Android, where `RootScreen` stops clearing it); the presentation in `Features/MainNavigation/` (iOS) and `ui/root/` (Android); the welcome line in `WelcomeView` and its Android twin.

### Out of scope

- Keeping a link across an app kill.
- « Partager »: #144.

## Acceptance criteria

- iOS, signed out, a book link touched from another app → the welcome screen with the waiting line; after signing in → the Fiche livre on Recherche, and the line is gone.
- iOS, signed out, a link then signing up a new account → the link's screen once the account exists.
- iOS, signed in, with « Modifier l'édition » open and a field edited, a book link touched → a sheet over the form with the Fiche livre and « Fermer »; « Fermer » → the form, the edit still there.
- iOS, the Profil sheet up, a list link touched → a sheet over the Profil with the list.
- iOS, « Ranger mes livres » up, a reader link touched → a sheet over it with the profile; closing it → the sort as it was.
- iOS, no modal up → the push on the link's tab, unchanged.
- Android emulator, the same cases with `adb shell am start -a android.intent.action.VIEW -d <link>` → the same results.
- Unit tests: `TabRouter` keeps a link while signed out and hands it over once signed in; a newer link replaces a waiting one.

## Implementation

stacked on: wa/144-add-share-links @ 920ac245

Autopilot round 1, 2026-11-16.

- iOS, waiting link
  - `TabRouter` now owned by `RootView` (`@State var router`), read from the environment by `MainTabView`; a sign-out (true → false) replaces it with a fresh one.
  - `TabRouter.linkAwaitingSignIn: DeepLink?`, `receive(_:isSignedIn:) -> DeepLink?` (held signed out, newer replaces), `takeLinkAwaitingSignIn()`.
  - `DeepLinkHandling` moved to `RootView` around both branches; `onChange(of: authModel.isAuthenticated)` opens the waiting link → sign-in and sign-up take the same path.
  - `WelcomeView`: line under the buttons, key `welcome.link_waiting` « Connectez-vous pour ouvrir ce lien. » (screen still in « vous »), en « Sign in to open this link. », id `e2e.welcome.linkWaiting`.
- iOS, over a modal
  - `LinkSheetPresenter.swift` (new, the one UIKit type): key window root → `presentedViewController` chain, skipping one being dismissed; anything presented = modal up (Profil and alerts included). Presents a `UIHostingController` page sheet.
  - Pure decision `TabRouter.open(_:on:isModalUp:) -> LinkSheetContent?`: modal up or Profil presented → `.destination`; else push as before → nil. `LinkSheetContent.swift` (new).
  - `LinkSheet.swift` (new): own `NavigationStack`, destination at root, « Fermer » (`action.close`, `e2e.linkSheet.close`), own shelf focus via new `View+ownsShelfFocus.swift` (also used by `ProfileSheet`).
  - Own username: Profil up → nothing; no modal → Profil sheet; another modal → `ProfileSheet` in the link sheet. Links no longer close the Profil.
  - `AppEnvironment.swift` (new): one modifier with every shared model, `authModel`, router, `syncUserData`, `.modelContext`, `.tint(.foregroundTinted)` (moved out of `ReCIT.swift`); used by `RootView` and the link sheet. SnackBar draws in its own window: nothing needed.
- Android
  - `RootScreen` no longer clears `incomingLinks` (StateFlow keeps the newest); `WelcomeScreen` line `R.string.welcome_link_waiting` when it parses.
  - `TabRouter.openLink(target): LinkLanding?` → `OnTab`, `InDialog`, null; covered = Profil presented or `overlayCount > 0`, fed by `CoversTabs()` (DisposableEffect) in every signed-in overlay (list form, list add search, relation request, group settings, create group, transaction request, shelf add books, shelf form, summary sheet, full-screen cover, create book, list scan, sort flow, link dialog). Any future bottom sheet needs a `CoversTabs()` line.
  - `ui/root/LinkDialog.kt` (new): full-screen `Dialog`, own Nav3 back stack, `LocalStackClose` turns the root top bar's back arrow into « Fermer »; back on root closes; a newer link replaces it (`key(target)`).
- Proof
  - iOS build green, no new SwiftLint violations; DeepLinkTests, TabRouterTests (23, 9 new), LinkedListTests, LinkedInventoryItemAndShelfTests, SharingVisibilityTests pass.
  - Android build green; TabRouterTest 14 (7 new), DeepLinkTest 17. No Android test for « waits signed out » (StateFlow simply not cleared).

## Review

## Verification

iPhone 17 simulator, signed in (implementer: no UI tool; PM checked the modal case):
- ✅ no modal, `/entity/isbn:9782070360024` → Fiche livre pushed on Recherche (implementer).
- ✅ Profil sheet up, same link → link sheet over the Profil with the Fiche livre and « Fermer » (PM).
- ✅ « Fermer » → the Profil as it was; the Profil's own close still works (PM).
- ❌ « Modifier l'édition » and « Ranger mes livres » cases not run.
- ❌ signed-out cases not run (simulator account must stay signed in): unit tests only.
- Android: no emulator, build + unit tests only.

## Feedback

### Round 1 — 2026-11-16 · #140 review findings, deferred here by Olivier

Asked: the three 🟡 of #140's validation review, for every link kind.

- Cold launch, my user unknown
  - iOS: `TabRouter.waitingLink` (was `linkAwaitingSignIn`), `receive(_:isMyUserKnown:)`, `takeWaitingLink()`. `DeepLinkHandling` passes `isAuthenticated && myUser != nil`; `.onChange(of: userModel.myUser?._id)` opens the waiting link (sign-in, sign-up and cold launch alike). Welcome line reads `router.waitingLink != nil`.
  - iOS, beyond the brief: on sign-out `RootView` builds the new router with `.init(waitingLink: router.waitingLink)`, so a cold launch whose session the server refuses keeps its link for the next sign-in.
  - iOS limit accepted: `syncMyUser` failing (offline cold launch) leaves the link waiting until a later sync succeeds.
  - Android was not safe (`restoreMyUserId` races the collector; after sign-in the pref is empty until `syncMyUser`): `MainScaffold` suspends on `users.myUserId.filterNotNull().first()`, then clears with `compareAndSet(url, null)` so a newer link wins.
- Refused URL on the link domain → same path + query on inventaire.io, at once, signed in or out, never waits
  - iOS `DeepLink.inventaireURL(for:)` (keeps percent-encoding, drops fragment, nil for other host/scheme), used in `onOpenURL` when `DeepLink(url:)` is nil.
  - Android `DeepLink.inventaireUrl(url)` on the raw string; `MainActivity.receive(intent)` (onCreate + onNewIntent) opens the browser and never puts it in `incomingLinks`.
- `User.mock(...)` in `User.swift`; `TabRouterTests` and `Fixture.user` use it.
- Proof: iOS build green, 56 tests pass (4 new). Android build green, DeepLinkTest 20 (3 new), TabRouterTest 14.
- Not driven on a device.
