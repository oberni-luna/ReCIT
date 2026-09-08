# ADR 0008 — Signing in, signing up, and where the session lives

- Status: Accepted
- Date: 2026-09-08
- Supersedes: nothing. It writes down what issues 0056–0059, 0068 and 0069 settled one at a
  time, because the pieces only make sense together — two of those issues were caused by
  changing one piece without the other.

## Context

`inventaire.io` authenticates with **cookies**, not tokens. A successful `POST /api/auth/login`
answers `200` and two `Set-Cookie` headers; every authenticated call afterwards is authenticated
by sending them back. There is no refresh token, no `Authorization` header, and no endpoint that
answers "who am I" without them.

Three properties of that server shape everything below, and all three were verified by hand
against production:

1. **The session is a signed, stateless cookie pair.**

   ```
   set-cookie: inventaire:session=eyJ1c2VyIjoiMzY4MjllMjEz…; path=/; expires=…6 months…; samesite=lax; secure; httponly
   set-cookie: inventaire:session.sig=cuCMaGQD6PYluiHJ7c-oZdxJG39Xgf1twwkbtjFOIrE; path=/; …
   ```

   The first cookie's value is unpadded base64url JSON. It is the payload; the second is its
   HMAC. Six months of expiry, and the server does **not** re-issue it on a request that already
   carries a valid one — so the pair captured at login stays valid, and can be persisted.

2. **Every public endpoint hands out an *anonymous* session, under those same two names.** The
   whole API sits behind a global `cookie-session` middleware. `GET /api/items/recent-public` —
   the one call the welcome screen's cover wall makes, before anybody has signed in — answers
   `200` and sets both cookies. So does a *refused* login. The presence of an
   `inventaire:session` cookie therefore proves nothing at all.

3. **The payload says who it belongs to.** That is what tells the two apart:

   ```
   GET  /api/items/recent-public  →  {"timestamp":1788900010063}
   POST /api/auth/login           →  {"user":"36829e21389c27c629a3181e31c36301","timestamp":1787493340761}
   ```

   Only signing in produces a payload that names a user.

The app must also survive being uninstalled and reinstalled without asking for the password
again — the session outliving an uninstall is the *point* of using the keychain — and must not
sign the user out because one call failed.

## Decision

One file speaks HTTP, cookies and keychain: `Features/Authentication/Service/AuthService.swift`.
Nothing else in the app touches any of the three. Every decision it makes that is not I/O lives
in a pure type under `Model/Authentication/`, tested without a network.

```
LoginView / CreateAccountView / ForgotPasswordView / ProfileView
        │  (typed throws AuthFailure, or a non-throwing outcome)
        ▼
AuthModel                    @Observable @MainActor, holds `isAuthenticated`
        │
        ▼
AuthService  ──────────────► inventaire.io          (URLSession.shared, cookies on)
     │     └──────────────► HTTPCookieStorage.shared (the jar: what gets sent)
     └────────────────────► Keychain                 (the record: survives an uninstall)

pure decisions:  AuthFailure · PostSignupSession · FieldAvailability
                 PasswordResetOutcome · SessionExpiry · SessionCookie
```

### Signing in

`POST /api/auth/login`, JSON `{username, password}`. The **documented path form** — the
`?action=` alias is deprecated server-wide — and no 404 fallback: two authentication paths
coexisting is two paths to debug later.

1. `AuthFailure.classify(status:serverMessage:)` turns the status into either `nil` (carry on) or
   a typed failure that already owns the sentence the user reads. The server's own English prose
   is decoded, carried for the log, and never rendered.
2. `absorbCookies(from:)` reads `Set-Cookie` off the response and writes it into the **injected**
   `HTTPCookieStorage`, rather than leaving it to `URLSession`'s own jar. In production the two
   are the same object; they agree only by coincidence, and a service handed a storage it never
   writes to cannot be tested.
3. A response that carried no session is `AuthFailure.noSessionCookies` — checked against the
   jar, not assumed from the `200`.
4. The pair is persisted to the keychain. A keychain that refuses the write is
   `AuthFailure.keychain(status:)`: at login time, being unable to remember the session is worth
   saying out loud.

### Signing up

`POST /api/auth/signup`, JSON `{username, email, password}`. **Signing up is one more way of
signing in**, not a thing of its own: same absorption, same keychain write, same "you are in" at
the end. Nobody retypes a password they chose ten seconds ago.

`PostSignupSession.next(hasSessionCookies:)` owns the one branch. Today the endpoint serialises
the session itself, so the common path is a single round trip; when it does not, a login is
chained with the credentials just used — which routes the rare branch through the path that is
exercised on every launch. The account exists either way by then: a failure after this point is
a failure to *open a session*, not to create an account.

Both fields are checked while typing, through `GET /auth/username-availability` and
`/auth/email-availability`. The endpoints answer "valid **and** free", which is why no naming
rule is written anywhere in this app. `FieldAvailability` owns what a field may be mid-typing,
including dropping a stale answer; a check that fails is `undetermined`, which says nothing on
screen and blocks nothing.

### Where the session lives, and which copy answers

Two copies, on purpose, because they fail differently:

| | The jar (`HTTPCookieStorage.shared`) | The keychain |
|---|---|---|
| What it is for | what actually gets **sent** on every request | the **record** of a session this app opened |
| Written by | `URLSession`, and `absorbCookies` | `login` / `signUp`, and `adoptJarSession` |
| Survives a relaunch | yes, iOS persists it | yes |
| Survives an uninstall | no | **yes** |
| Can be forged by public traffic | **yes** — see property 2 above | no |

`isLoggedIn()` answers from the keychain first. If the keychain is empty it reads the jar, and
accepts what it finds **only when the payload names a user** — `SessionCookie.namesAUser(_:)`.
That second clause is not the mere presence that property 2 forbids: an anonymous session names
nobody, and only signing in produces one that names somebody.

`adoptJarSession()` runs from the initialiser, right after the keychain's cookies are restored
into the jar: when the jar holds a session that names a user, it is copied into the keychain. So
a session that exists in only one of the two places ends up in both, and the keychain goes back
to being the record.

Both halves are there because both single points of failure have already cost a release:

- **Trusting the jar alone** (before issue 0068) meant the welcome screen's own cover wall put an
  anonymous cookie in the jar after a sign-out, and the next launch opened on the tabs of
  nobody — every call `401`, the first-sync placeholder spinning for ever.
- **Trusting the keychain alone** (issue 0069, the fix for 0068) meant every install that had
  signed in under an earlier build launched signed out, because its session was in the jar and
  the keychain had never had to be written. It asked for the password at every single launch.

### Keeping public traffic out of the session

Not believing the jar is no reason to keep filling it. Two mechanisms, one rule:

- The two availability checks and the reset call set `httpShouldHandleCookies = false` on the
  request — they must touch the session in neither direction.
- Everything else public goes through `URLSession.cookieless` (`httpShouldSetCookies = false`,
  `httpCookieAcceptPolicy = .never`, `httpCookieStorage = nil`), handed to the model that needs
  it by the composition root as a second `APIServicing`. `RootView` builds exactly two:
  `apiService` carries the session, `publicAPIService` does not.

**A new call made before there is a user goes through `publicAPIService`.** That is the rule the
cover wall broke when it was added (issue 0068), and the reason `URLSession.cookieless` exists as
a named thing rather than a flag on one request.

### Asking for a new password

`POST /auth/reset-password` is the opposite kind of call: it opens no session, absorbs no cookie,
and **reports nothing the server said**. The controller mails the link when it finds a user and
answers `400 {message: "email not found"}` when it does not, so passing the answer along would
answer "does this account exist?" for any address somebody types. `PasswordResetOutcome` collapses
every answer onto one confirmation; the service's only job is to tell an answer from no answer at
all.

### Signing out, and being signed out

`logout()` tells the server and then forgets the session locally **whatever the server said** — a
user who taps « se déconnecter » on a plane must still end up signed out of this phone. It
deletes the two named cookies and only those (it used to empty the whole jar, which signed the
user out of every other host the app had ever contacted), and deletes the keychain entry. Nothing
is left for `adoptJarSession` to find.

Being signed out *by the server* is one status and one status only. `SessionExpiry.isSessionGone(_:)`
answers `true` for `401` and nothing else — a `403` is a session the server **did** recognise and
a thing it will not let that account do, and signing the user out would be the wrong cure.
`RootView+RefreshUserData` drops the session on a `401` from the first call of the sync, so the
app shows the authentication flow instead of spinning behind placeholders that can never fill.

### The keychain entry itself

`Keychain` (`Features/Authentication/Service/Keychain.swift`) is `Data` in, `Data` out, under a
key. One `kSecClassGenericPassword` item, `kSecAttrService` and `kSecAttrAccount` both set to the
key, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — available to a launch the user started,
never synced to iCloud, never leaving the device.

The key is namespaced per environment by `Env.keychainKey`
(`asso.recits.auth.cookies` / `…​.dev`), which is mostly what `Env` is *for*: both cases point at
`https://inventaire.io`, so switching environment switches the keychain namespace and nothing
else.

The value is the cookie pair, `NSKeyedArchiver`-archived with `requiringSecureCoding: true` and
read back with `requiresSecureCoding = true`. Two notes on that round trip:

- The classes are listed by hand (`[NSArray.self, HTTPCookie.self]`) rather than through
  `decodeArrayOfObjects(ofClass:)`: `HTTPCookie` supports secure coding but the Swift overlay does
  not restate the conformance, so the generic form will not compile against it.
- It works on iOS and **fails on macOS**, where `NSHTTPCookie` does not adopt `NSSecureCoding`
  ("This decoder will only decode classes that adopt NSSecureCoding"). Anything sharing this code
  with a Mac target has to stop using the archiver, not lower the flag.

An entry that cannot be read is deleted rather than re-failing at every launch, and the cookies
are filtered by name on the way **out** as well as in, so an entry written by an older build
under a wider rule cannot widen what counts as a session today.

The end-to-end scenario needs the opposite of all this — a guaranteed signed-out first step —
which is why `UITestHooks.prepareLaunch()` wipes the keychain entry, the jar, the onboarding
answers and the store when the app is launched with `-uitest -uitest-reset`, before `AuthService`
is built. It is compiled out of Release entirely.

## Consequences

- **One place to change.** Anything about sessions — a new endpoint, a rotated cookie name, a
  second server — is `AuthService.Config` plus `AuthService`. Nothing else imports `Security` or
  touches `HTTPCookieStorage`.
- **Every classification is testable without a network**, and is tested: `AuthFailure`,
  `PostSignupSession`, `FieldAvailability`, `PasswordResetOutcome`, `SessionExpiry`,
  `SessionCookie`. `AuthServiceTests` covers the I/O over `MockURLProtocol`, with a per-test
  keychain key and cookie jar.
- **`isAuthenticated` is read once, at launch**, from `AuthService.isLoggedIn()` — never a
  default that guesses the answer before the question is asked. It then moves only on a login, a
  sign-up or a sign-out.
- **The session cookie's payload is now load-bearing.** If inventaire.io changes what it
  serialises, `SessionCookie` degrades to `.unreadable`, which is deliberately *not* taken for a
  user: the keychain still answers, and the jar clause stops helping. `SessionCookieTests` pins
  both real payloads so the change shows up as a test failure and not as a support ticket.
- **A restart is checked end to end.** Step 2 of the scenario quits the app and opens it again
  without the reset wipe, and reports KO if the welcome screen comes back
  ([feature 0012](../features/0012-end-to-end-scenario.md)).

## Rules for new code

1. A call made before there is a user goes through `publicAPIService` / `URLSession.cookieless`.
2. Nothing outside `AuthService` reads or writes cookies, the keychain, or decides who is signed
   in. Ask `AuthModel`.
3. A `*Model` that meets a `401` lets it out. `refreshUserData` is where a dead session is turned
   into a sign-out; a model that swallows it turns it into a spinner.
4. A new server answer worth a sentence is a case on the pure type, not an `if` in the service.

## See also

- [Feature 0011 — Ex-libris, the pre-login welcome and the native account flow](../features/0011-ex-libris-pre-login-onboarding.md) — the screens, and why they are shaped that way.
- [Issue 0068 — a signed-out app launches signed in](../issues/0068-a-signed-out-app-launches-signed-in.md).
- [Issue 0069 — every launch asks for the password again](../issues/0069-every-launch-asks-for-the-password-again.md).
