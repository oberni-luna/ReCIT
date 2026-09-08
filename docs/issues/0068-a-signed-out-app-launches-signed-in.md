Title: A signed-out app launches signed in, spins for ever, and says nobody is connected
Labels: bug
Type: fixed in this change

## Parent

Feature: `ReCIT_iOS/Features/Authentication/Service/AuthService.swift` (`isLoggedIn()`), read by
`AuthModel.init` and branched on by `ReCIT_iOS/Features/MainNavigation/RootView.swift`.
Reported on 2026-09-06 from a device, on the branch that added the welcome cover wall
(feature 0013).

## What happened

After signing out, the app sometimes launched **as if signed in**: the tabs came up, nothing
ever loaded, and the "Synchronisation de vos données…" placeholder spun for ever. The Profile
tab, on the same launch, said « Vous n'êtes pas connecté. »

Both statements were true. `AuthModel.isAuthenticated` was `true`, so `RootView` showed
`MainTabView`; `UserModel.myUser` was `nil`, because `GET /api/user` answered `401`, which is
what `ProfileView` renders `anonymousView` for.

## Why

`AuthService.isLoggedIn()` asked the **cookie jar** whether an `inventaire:session` cookie was
held. That is not a question about who is signed in.

inventaire.io sits behind a global `cookie-session` middleware, so *any* public endpoint hands
out an anonymous session under the two names a real one uses. Verified against production:

```
$ curl -s -D - -o /dev/null "https://inventaire.io/api/items/recent-public?limit=2"
HTTP/2 200
set-cookie: inventaire:session=eyJ0aW1lc3RhbXAiOjE3ODg3MjIzMDkwMjl9; path=/; expires=Fri, 05 Mar 2027 …
set-cookie: inventaire:session.sig=5he_p3J7JEU-…; path=/; expires=Fri, 05 Mar 2027 …
```

`/api/items/recent-public` is the one call `CoverWallModel` makes, and it ran through the shared
`URLSession` — so the welcome screen the user lands on **after signing out** put a six-month
session cookie straight back in the jar. The next launch read it and opened on the tabs.

The two availability checks and the reset call were already protected with
`httpShouldHandleCookies = false` for exactly this reason (issues 0057, 0058). The cover wall was
new, went through `APIService`, and nobody thought to protect a call that asks for nothing.

The infinite spinner is the second half: `RootView+RefreshUserData` returns on the first failure,
so no domain sync ever ran, and `SyncStatusStore` never left `.pending` — a dead end with
nothing on screen to tap.

## The fix

1. **The keychain is the record, not the jar.** `isLoggedIn()` reads the cookies this app
   persisted itself — written only on a successful `login` / `signUp`, deleted on `logout`. An
   anonymous cookie cannot forge that.
2. **Pre-login traffic stops taking cookies at all.** `URLSession.cookieless`, handed to the
   cover wall by the composition root as a second `APIServicing`.
3. **A dead session is no longer a dead end.** `SessionExpiry.isSessionGone(_:)` — `401` only,
   never `403` — makes `refreshUserData` drop the session, so `RootView` shows the
   authentication flow instead of spinning.
4. **A way out from the screen that tells the truth.** `ProfileView.anonymousView` gained a
   primary "Se connecter" button, which signs out (dropping the stale session) and so lands on
   the authentication flow.

Regression tests: `AuthServiceTests.anAnonymousCookieInTheJarIsNotASession`,
`AuthServiceTests.signingOutSurvivesAnAnonymousCookie`, `SessionExpiryTests`.
