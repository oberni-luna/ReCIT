# Ex-libris — the pre-login welcome and the native account flow

Shipped on 2026-08-28 from PRD `docs/prd/0010-ex-libris-pre-login-onboarding.md`.

## What it does

A logged-out launch now opens on a welcome screen that says what the app is for — inventory your books,
keep track of what you lend, borrow from people you know — instead of a form and a sentence telling you
to go and register on a website. From there you sign in, create an account, or ask for a new password,
all inside the app.

The app is called **Ex-libris**.

Once signed in, nothing changed: the existing scan-then-sort onboarding (PRD 0007) takes over on its own
when the inventory turns out to be empty.

## Technical surface

**Screens added** — all under `Features/Authentication/View/`, behind a `NavigationStack` in the
unauthenticated branch of `RootView`:

- `WelcomeView` — the unauthenticated root. The app name, three value rows, `Se connecter`,
  `Créer un compte`.
- `LoginView` — rewritten as the sign-in screen (filename kept; the design library points at it).
- `CreateAccountView` — three fields, with a live availability check on the username and the address.
- `ForgotPasswordView` / `PasswordResetSentView`.
- `AuthFlowView` + `AuthDestination` — the stack and its destinations. `AuthField`, `WelcomeValueRow`
  are the shared pieces.

**Pure types** — `Model/Authentication/`, no SwiftUI and no networking, tested without a network:

- `AuthFailure` — classifies a server answer *and* owns the sentence the user reads.
- `FieldAvailability` — what a field can be while typing, including dropping a stale answer.
- `PostSignupSession` — whether a sign-up needs a chained sign-in.
- `PasswordResetOutcome` — collapses every server answer except a transport failure onto one
  confirmation.

**Endpoints** (server `https://inventaire.io/api`, verified against the live OpenAPI spec):
`POST /auth/login`, `POST /auth/logout`, `POST /auth/signup`, `POST /auth/reset-password`,
`GET /auth/username-availability`, `GET /auth/email-availability`.

**Also touched**: `AuthModel` is `@Observable`; `Keychain` split out of `AuthService`;
`MockURLProtocol` gained a per-session handler; `OnboardingScreenLayout` and the new
`OnboardingScreenContent` handle Dynamic Type; `SearchResult`'s `Hashable` is written out by hand.

**Tests**: 484 passing, 1 skipped. Suites added — `AuthFailure`, `AuthService`, `FieldAvailability`,
`PostSignupSession`, `PasswordResetOutcome`. Nothing was added to the production-hitting integration
suite.

## Notable decisions

- **The welcome screen is the unauthenticated root, and nothing remembers it was seen.**
  `OnboardingStore` is keyed by user id and defends that on purpose — a first launch belongs to an
  account, not to a phone. Before signing in there is no user id, so "show it once" would need a
  device-wide flag that store explicitly refused. Being logged out *is* the state that needs the pitch.

- **`Créer un compte` replaces the stack rather than pushing onto it.** It exists on both the welcome
  and the sign-in screen; without this the stack could grow
  `welcome → sign-in → sign-up → sign-in → …`. Depth never exceeds one.

- **The availability endpoints hand out a session cookie.** `GET /auth/username-availability` answers
  `200` with `Set-Cookie: inventaire:session` — an anonymous session, under the exact two names
  `AuthService` reads to decide whether someone is signed in. Typing into the username box and
  relaunching opened the app on the tabs of an account that does not exist. The server applies
  `cookie-session` globally, so **every public auth request must set `httpShouldHandleCookies = false`
  and must not call `absorbCookies`** — only `login` and `signUp` may absorb. Two tests hold this;
  do not remove them when adding an endpoint.

- **No server-authored prose ever reaches a screen.** Errors come back as `{ status, message }` in
  English. Classification reads `error_name` first and the sentence only as a fallback token, because a
  *taken* username carries no `error_name` — only prose. A rejected password is never echoed: the server
  writes the password back inside its own message.

- **The reset confirmation is deliberately vague, because the server is not.** Its controller turns a
  failed lookup into `400 "email not found"` and echoes the address. Every answer except a transport
  failure therefore collapses onto one confirmation in `PasswordResetOutcome` — the collapse is the
  whole protection, not a nicety.

- **Sign-up never makes the user retype.** If the response carries no session cookies, a sign-in is
  chained with the credentials just used. That branch is unreachable in production today, which is
  exactly why it is unit-tested.

- **`AuthService.absorbCookies` exists because the injected cookie storage used to be decorative.** The
  service never wrote to it — `URLSession` did, into its own jar. They coincide in production and
  diverge under an ephemeral test session, which would have made the service tests test nothing.

- **`SearchResult`'s `Hashable` is hand-written.** It was synthesised over a SwiftData `@Model`, whose
  conformance the compiler only sees when both files land in the same batch of a batch-mode build.
  Adding unrelated files anywhere in the target broke the build in a file nobody had touched.

- **`ViewThatFits` must not wrap a screen that raises a keyboard.** The three account screens were
  built with it, copying the onboarding layout. Focusing a field raised the keyboard, which shrank
  the available height, which made `ViewThatFits` pick a different branch, which rebuilt the
  `TextField` at a different place in the view tree — SwiftUI read that as a different view and
  dropped the focus. The username field could not be typed into at all. They now use one
  arrangement: a `ScrollView` with the actions pinned by a bottom safe-area inset, which handles
  the accessibility sizes just as well and cannot change identity. `WelcomeView`, the reset
  confirmation and the onboarding screens keep `ViewThatFits` — nothing on them raises a keyboard.

- **Onboarding uses `ViewThatFits` over three arrangements**, not a pinned bottom inset. C2b's answers
  are a three-sentence reason plus two controls; as an inset that block ate the whole screen at AX5 and
  truncated its own reason. The default-size layout is provably unchanged — captured before and after
  as byte-identical PNGs.

## Still open

- **`logout` has never been exercised against production.** The paths moved off the deprecated
  `?action=` form; `login` was verified by hand, `logout` was not. Required before shipping.
- **Associated domains** (`webcredentials:inventaire.io`) need a file hosted by inventaire.io. It is
  ready, with its notice, in `docs/integrations/`.
- **Sign-out from the app** was never exercised during this work, to avoid ending the owner's session.
- The string catalogue mixes `login.*` with `signup.*`, `welcome.*` and `auth.error.*`. Deliberate —
  renaming seven translated keys buys nothing — and tracked separately.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> To read them: `git log --diff-filter=D --oneline -- issues/` then `git show <commit>^:<path>`.

- `issues/0055-authmodel-observable.md` — AuthModel becomes @Observable — commit `9f5b6d8`
- `issues/0056-sign-in-from-a-welcome-screen.md` — sign in from a welcome screen — commit `2cb2836`
- `issues/0057-create-an-account-without-leaving-the-app.md` — create an account — commit `32e0fd7`
- `issues/0058-ask-for-a-new-password.md` — password reset — commit `cfee024`
- `issues/0059-rename-the-app-ex-libris.md` — the app is called Ex-libris — commit `87c6a68`
- `issues/0060-onboarding-survives-a-big-font.md` — onboarding at accessibility sizes — commit `4fc653f`
