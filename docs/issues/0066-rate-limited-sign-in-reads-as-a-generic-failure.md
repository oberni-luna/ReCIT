Title: Say so when inventaire.io is rate-limiting the sign-in
Labels: needs-triage
Type: AFK

## Parent

Feature: docs/features/0011-ex-libris-pre-login-onboarding.md
Found while building docs/features/0012-end-to-end-scenario.md

## What to build

`inventaire.io` rate-limits `POST /api/auth/login` and answers `429` with
`{"status":429,"message":"Too many requests. See https://api.inventaire.io"}`.

`AuthFailure.classify(status:serverMessage:)` maps everything that is not a 401 or a 403 onto
`.server(status:serverMessage:)`, whose sentence is « Une erreur est survenue. Réessayez plus
tard. » So a user who has mistyped their password a few times in a row — or, on a shared
network, one who has done nothing at all — is told that something went wrong, with no hint that
waiting is exactly what will fix it and that their credentials were never the problem.

The end-to-end scenario meets this on every second run, which is how it was found: the report
row reads « Connexion refusée. L'écran indique : "Une erreur est survenue. Réessayez plus
tard." » where the real answer is "you have signed in too often in the last few minutes".

Add a `case rateLimited` to `AuthFailure`, classify `429` onto it in **both** classifiers (the
sign-up endpoint is rate-limited too), and give it a sentence that names the wait — something
like « Trop de tentatives. Réessayez dans quelques minutes. » The existing suite already asserts
that no server prose reaches `message`, so the new case has to carry its own catalogue resource
like every other one.

## Acceptance criteria

- `AuthFailure.classify(status: 429, serverMessage:)` returns `.rateLimited`, and so does the
  sign-up classifier.
- The sentence is a catalogue resource, French and English, and says that waiting is the fix.
- The sign-in screen shows it under both fields, as it shows every other sign-in failure; the
  sign-up screen shows it where a non-attributable failure goes, since a 429 belongs to no field.
- A test covers the mapping, alongside the existing ones for 401/403 and the arbitrary-status
  property.
