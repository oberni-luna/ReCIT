---
issue: 143
status: todo
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

## Review

## Verification

## Feedback
