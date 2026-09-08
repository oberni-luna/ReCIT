Title: Every launch asks for the password again
Labels: bug, regression
Type: fixed in this change

## Parent

Feature: `ReCIT_iOS/Features/Authentication/Service/AuthService.swift` (`isLoggedIn()`), read by
`AuthModel.init` and branched on by `ReCIT_iOS/Features/MainNavigation/RootView.swift`.
Regression introduced by the fix for [issue 0068](0068-a-signed-out-app-launches-signed-in.md),
in commit `cc9ddce`. Reported on 2026-09-08.

## What happened

Restart the app and it opens on the welcome screen: sign in, use the app, quit, open it again,
sign in again. Every time.

## Why

Issue 0068 moved `isLoggedIn()` off the cookie jar and onto the keychain, and moved
`AuthModel.isAuthenticated` off a hard-coded `true` and onto that answer. Both changes were
right. Together they made the keychain the **only** record of a session — and for every install
that already existed, the keychain was empty.

It was empty because it had never had to be full. `isAuthenticated` used to default to `true`,
so the app went to the tabs whatever `isLoggedIn()` said; the session that made the calls work
was the cookie in `HTTPCookieStorage.shared`, which iOS persists across launches on its own.
Verified on the simulator the bug was reported from: the app's jar held a real session —

```
$ strings …/Library/Cookies/studio.lunabee.nouveau-recit.binarycookies
inventaire.io
inventaire:session
eyJ1c2VyIjoiMzY4MjllMjEzODljMjdjNjI5YTMxODFlMzFjMzYzMDEiLCJ0aW1lc3RhbXAiOjE3ODc0OTMzNDA3NjF9
```

— which decodes to `{"user":"36829e21389c27c629a3181e31c36301","timestamp":1787493340761}`,
while the same device's keychain held no entry for the app's access group at all. So the launch
read an empty keychain, showed the welcome screen, and threw away a session that was sitting
right there and still valid for six months.

## Why the tests did not catch it

`AuthServiceTests.aPersistedSessionSurvivesANewService` covers the round trip that *follows a
login this build ran*. Nothing covered the state every existing install was actually in — a
session in the jar and nothing in the keychain — because that state cannot be reached by calling
`login`. It has to be set up.

## The fix

**A cookie that names a user is a session.** The reason 0068 stopped believing the jar was that
the *name* `inventaire:session` proves nothing: every public endpoint hands out an anonymous one
under it. The **value** does prove something, and the two are trivially told apart —

```
GET /api/items/recent-public   →  {"timestamp":1788900010063}
POST /api/auth/login           →  {"user":"36829e…","timestamp":1787493340761}
```

— both verified against production. Only signing in produces a payload that names somebody.

1. **`SessionCookie`** (`Model/Authentication/SessionCookie.swift`) — pure, on the pattern of
   `AuthFailure` / `SessionExpiry`: base64url-decodes a cookie value and answers `.user(id:)`,
   `.anonymous` or `.unreadable`. A value that does not decode is never taken for a user.
2. **A launch adopts a signed-in session out of the jar.** `AuthService.adoptJarSession()`, run
   from the initialiser right after the restore, writes it to the keychain — so the session
   survives an uninstall from then on, and the keychain goes back to being the record. An
   anonymous session is never adopted, which leaves 0068 fixed.
3. **`isLoggedIn()` reads the jar as a second answer**, and only for a session that names a
   user. This is what stops the keychain being a single point of failure for staying signed in:
   a write that did not happen costs a re-sync, not a re-login.

Sign-out is untouched: it deletes the keychain entry *and* the jar's session cookies, so there
is nothing left to adopt.

Regression tests: `SessionCookieTests` (five cases, on the two payloads production serialises),
`AuthServiceTests.aUserSessionInTheJarSurvivesAnEmptyKeychain`,
`AuthServiceTests.anAnonymousJarIsNeverAdopted`, and step 2 of the end-to-end scenario —
« Redémarrage de l'application », which quits the app and opens it again without the
`-uitest-reset` wipe and reports KO if the welcome screen comes back
([feature 0012](../features/0012-end-to-end-scenario.md)).
