---
issue: 47
status: to-close
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

## Implementation

- `auth/model/AuthFailure.kt`: `data object RateLimited`; `classify` maps `429` onto it (after 401/403, every other status unchanged); `message` → `R.string.auth_error_rate_limited`; `signupField` null through the existing `else`. KDoc: three failures told apart on screen (wrong credentials, no network, too many attempts), everything else one sentence.
- `res/values/strings.xml`: `auth_error_rate_limited` « Trop de tentatives. Réessayez dans quelques minutes. », beside the other `auth_error_*`.
- `test/…/auth/AuthModelTest.kt` (holds `AuthFailureTest`): `too_many_attempts_is_429_on_sign_in_and_sign_up` (classify and classifySignup 429 → RateLimited, message, null signupField); the 401/403/500 test also checks `Server(500).message` is the generic sentence.
- Sign-up unchanged: `classifySignup` already hands every non-400 status to `classify`. No screen touched.
- Build: `./gradlew :app:assembleDebug` ✅ · `./gradlew :app:testDebugUnitTest` ✅ 601 tests, 0 failures.
- Runtime not run: no inventaire.io credentials for the agent; the two on-screen criteria follow from unchanged screens reading only `message` / `signupField`.

## Review

### Round validation — 2026-11-10

- Scope: `origin/sprint/android-1-4-0...wa/47-fix-android-sign-in-429-message`.
- Verdict: clean. `LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓`.
- Wiki: nothing task-specific; the sprint's feature doc is written with #101.
- Screenshots: none — `verify.platform: ios`, this task is Android.

## Verification

manual validation — not run by agent (no inventaire.io credentials; build + unit tests are the proof)

## Feedback
