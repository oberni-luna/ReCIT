# A sign-in refused for too many attempts says to wait

Shipped on 2026-11-06, iOS only (issue #7). inventaire.io rate-limits `POST /api/auth/login` and answers `429`.
The app read that answer like any other server error and showed « Une erreur est survenue. Réessayez plus tard. »
A reader who had mistyped the password a few times, or who shares a network with others, was told that something
went wrong, with no hint that waiting is the fix. `scripts/e2e.sh` met it on every second run
([0012](0012-end-to-end-scenario.md)). Now a `429` has its own sentence.

## What it does

- Connexion, server answering `429`: « Trop de tentatives. Réessayez dans quelques minutes. » (en « Too many
  attempts. Try again in a few minutes. ») shows under both fields, where every sign-in failure already shows.
- Account creation, server answering `429`: the same sentence, where failures that belong to no field already show.
  This is why the sentence does not say « de connexion ».
- Wrong credentials (`401`, `403`) still read « Nom d'utilisateur·ice ou mot de passe incorrect. ». A `500` and
  every other status still read « Une erreur est survenue. Réessayez plus tard. »
- Both screens still say « vous »: the sentence follows them (see the voice note in `docs/conventions/wording.md`).

## Technical surface

- `Model/Authentication/AuthFailure.swift`: a new `case rateLimited`. `classify(status:serverMessage:)` maps `429`
  onto it. `classifySignup` hands every status but a `400` to `classify`, so sign-up gets it with no change of its
  own. `signupField` is `nil`; `message` is the catalogue key `auth.error.rate_limited`. The file header now says three
  failures are told apart on screen — wrong credentials (type again), no network (find one), too many attempts
  (wait) — and everything else is one sentence.
- The rule of [ADR 0008](../adr/0008-session-login-signup-keychain.md) holds: the server's own English prose
  (« Too many requests. See https://api.inventaire.io ») is carried for the log, never rendered.
- No view changed: `LoginView` and `CreateAccountView` read only `message` and `signupField`, and the only exhaustive
  switches are in `AuthFailure.swift`.
- `PasswordResetOutcome` (every answer reads as sent, by design) and `FieldAvailability` (a `429` is `undetermined`,
  by design) are untouched.
- Tests: four in `AuthFailureTests`, next to the `401` / `403` ones — `classify` on a `429` with the real server
  message and with none, `classifySignup` on a `429`, `signupField` `nil`, and a message distinct from the generic,
  invalid-credentials and network ones. The test writes `.init(localized:)` so the lines frozen in
  `.swiftlint.baseline` keep matching; the baseline did not grow.

## Not done / owed

- Android: `Recit_Android/…/auth/model/AuthFailure.kt` has the same gap, out of scope here (draft task #47).
- Not seen on screen: the agent did not make the sign-in screen meet a real `429`. Owed by hand: the new sentence
  under both fields, and a wrong password still reading « Nom d'utilisateur·ice ou mot de passe incorrect. ».
  e2e was not run.
