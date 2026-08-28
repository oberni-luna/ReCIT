Title: Se connecter, from a welcome screen that says what the app is for
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0010-ex-libris-pre-login-onboarding.md

## What to build

A logged-out launch opens on a welcome screen instead of a form: the app's name, its three uses in
three lines, `Se connecter` as the primary action and `Créer un compte` under it. Signing in from
there reaches the tabs, exactly as it does today.

End to end: the screen, the navigation that carries it, the documented endpoints underneath, the
error messages the user actually reads, and the field hints that let a password manager fill the form.

`Créer un compte` pushes a screen that only says the flow is coming — issue 0057 builds it. Nothing
else in this slice is a placeholder.

### The welcome screen is the unauthenticated root

The root view renders it instead of the login form. It is therefore seen on every logged-out launch,
and **nothing is persisted about having seen it**.

That is a decision. `OnboardingStore` is keyed by user id and its own header defends why — a first
launch is a property of an account, not of a phone. Before signing in there is no user id, so
"show the pitch once" would need a device-wide flag, which that file explicitly refused. And being
logged out *is* the state that needs the pitch.

### Navigation

Its own `NavigationStack` in the unauthenticated branch, with its own destination enum. **Not**
`NavigationDestination`: that one carries SwiftData payloads and describes the authenticated entity
browser.

`Créer un compte` exists on the welcome screen **and** on the sign-in screen. From sign-in it
**replaces** the stack rather than pushing onto it, so the stack never exceeds one level and
`accueil → connexion → création → connexion → …` cannot be built.

### It has to survive a big font

The pitch scrolls, with the two actions pinned by a bottom safe-area inset. Two cases overflow it: a
small iPhone, and the accessibility text sizes. The action most users came for must never be the thing
that leaves the screen.

Do not reuse `OnboardingScreenLayout`: it holds an illustration slot this screen does not want, and
its own header says it exists because its two screens *are* the same screen twice. This one is not.

### The endpoints, and four fixes on the way

`AuthService` moves onto the documented paths — `/auth/login` and `/auth/logout`. The `?action=` form
the code uses is deprecated server-wide; `POST /api/auth/login` was verified by hand against production
and returns `loggedIn`, `inventaire:session` and `inventaire:session.sig`.

Three defects are corrected on lines this slice touches anyway:

1. **Logging out purges every cookie** in the shared storage, not only inventaire's — it breaks the
   session of any other host the app has talked to. Persistence filters correctly; the asymmetry is
   the bug. Scope the deletion to the configured session cookie names.
2. **Secure coding is off** on both cookie archive and unarchive, though `HTTPCookie` supports it.
3. **The service's error messages are hard-coded French**, outside the catalogue — the D20/D37 defect,
   in the most visible file of the flow.

### No English server prose reaches the screen

Errors come back as `{ status, message }` where `message` is written by the server, in English. A
**pure type** — no networking, no SwiftUI, on the pattern of `OnboardingGate` — maps status and message
onto our own cases. Refused credentials and a network failure read differently; everything else falls
to one generic message. The server's text goes into the error value, never to the user.

### Autofill

The username and password fields declare what they hold, so the keychain offers saved credentials.
The project has no `textContentType` anywhere today, which is why signing in currently ignores a
password the user already has.

Associated domains — which would surface a password saved on the website — are out of scope: they need
a file hosted by inventaire.io. It is ready in `docs/integrations/`.

## Acceptance criteria

- [ ] A logged-out launch shows the welcome screen, not the sign-in form
- [ ] It names the app and states the three uses: inventorier, prêter, emprunter
- [ ] It says the account is an inventaire.io account
- [ ] `Se connecter` reaches the sign-in screen; a valid sign-in reaches the tabs
- [ ] `Créer un compte` is reachable from both the welcome and sign-in screens
- [ ] From sign-in, it replaces the stack rather than pushing; the stack never exceeds one level
- [ ] Signing out returns to the welcome screen
- [ ] At the largest accessibility text size, and on a 667pt-tall device, the pitch scrolls and both
      actions stay on screen
- [ ] Light and dark, with no literal colours and no hard-coded font sizes
- [ ] `login` and `logout` use `/auth/login` and `/auth/logout`; no `?action=` remains in the codebase
- [ ] Logging out deletes only the configured session cookies; another host's cookies survive it
- [ ] Cookie archiving and unarchiving both require secure coding
- [ ] A pure type maps (status, server message) onto our error cases, importing no networking
- [ ] Wrong credentials and no network produce different, French messages
- [ ] No server-authored string is ever displayed
- [ ] Username and password fields carry their content types; the keychain offers saved credentials
- [ ] All copy lives in `Localizable.xcstrings` with English as the source value and a French translation
- [ ] `login.noaccount.explanation` is removed — it told the user to go elsewhere, which is no longer true
- [ ] Test suite on the error mapping, including that no input surfaces the server's message
- [ ] Test suite on the service against `MockURLProtocol`: success, refusal, network failure, and a
      logout that spares other hosts' cookies
- [ ] Tests inject their own cookie storage and a unique Keychain key, and leave neither behind
- [ ] Nothing is added to the integration suite
- [ ] `logout` verified by hand on device against production before this ships

## Blocked by

- issues/0055-authmodel-observable.md
