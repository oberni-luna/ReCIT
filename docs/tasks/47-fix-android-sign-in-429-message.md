---
issue: 47
status: todo
wiki: [[features/0083-rate-limited-sign-in-message]], [[adr/0008-session-login-signup-keychain]]
note: Android half of #7. Recit_Android/…/auth/model/AuthFailure.kt maps 429 onto Server; add RateLimited, same copy as iOS.
created: 2026-11-09
---

## Context / Decisions

> Android half of #7: Recit_Android/…/auth/model/AuthFailure.kt maps 429 onto Server; add RateLimited, same copy as iOS (« Trop de tentatives. Réessayez dans quelques minutes. »).

Port of iOS [0083](../wiki/features/0083-rate-limited-sign-in-message.md).

- `AuthFailure.RateLimited` (`auth/model/AuthFailure.kt`); `classify` maps `429` onto it. `classifySignup` already hands every status but `400` to `classify`: sign-up gets it with no change of its own.
- `signupField` is null, so on Création de compte it shows where field-less failures show; on Connexion where every sign-in failure shows. No screen changes.
- `message` → new string `auth_error_rate_limited`: « Trop de tentatives. Réessayez dans quelques minutes. » (French only on Android).
- The server's prose stays in the log, never rendered (ADR 0008). `401` / `403` and every other status unchanged.
- The file's KDoc says three failures are told apart: wrong credentials, no network, too many attempts; everything else is one sentence.

## Acceptance criteria

- `classify(429, "Too many requests…")` is `RateLimited` (unit test); `classifySignup(429, …)` too.
- `401` and `403` still `InvalidCredentials`; `500` still `Server` → « Une erreur est survenue. Réessayez plus tard. » (unit test).
- Connexion answered `429`: « Trop de tentatives. Réessayez dans quelques minutes. » under the fields.
- Création de compte answered `429`: the same sentence in the general error place, not under a field.
