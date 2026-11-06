---
issue: 7
status: to-close
wiki: [[architecture]], [[testing]]
note: migrated from docs/issues/0066 — a 429 on sign-in reads as a generic failure
created: 2026-11-06
---

## Context / Decisions

> `inventaire.io` rate-limits `POST /api/auth/login` and answers `429` with
> `{"status":429,"message":"Too many requests. See https://api.inventaire.io"}`.
> `AuthFailure.classify(status:serverMessage:)` maps everything that is not a 401 or a 403 onto
> `.server(status:serverMessage:)`, whose sentence is « Une erreur est survenue. Réessayez plus
> tard. » So a user who has mistyped their password a few times in a row — or, on a shared
> network, one who has done nothing at all — is told that something went wrong, with no hint that
> waiting is exactly what will fix it. Found by `scripts/e2e.sh`, which meets it on every second run.

- **Problem:** `Model/Authentication/AuthFailure.swift` sends a `429` to `.server`, shown as `auth.error.generic`.
- **Fix:** a new `case rateLimited` on `AuthFailure`; `classify` maps `429` onto it.
- **Sign-up:** `classifySignup` already hands every non-400 status to `classify`, so it gets `.rateLimited` with no change of its own.
- **`signupField`:** `.rateLimited` → `nil`. The sign-up screen shows it where non-attributable failures already go; the sign-in screen under both fields, like every sign-in failure.
- **Copy:** one catalogue resource for both screens (both still use « vous »):
  - fr « Trop de tentatives. Réessayez dans quelques minutes. »
  - en « Too many attempts. Try again in a few minutes. »
  - « de connexion » dropped on purpose: the same sentence shows on account creation.
- **Rule kept:** no server prose reaches `message`; the existing arbitrary-status property test must still pass.
- **Out of scope (YAGNI):** Android (`Recit_Android/…/auth/model/AuthFailure.kt`, same gap) → separate draft task. `PasswordResetOutcome` (reports every answer as `.submitted` by design) and `FieldAvailability` (429 → `undetermined` by design) untouched.

## Acceptance criteria

- [ ] `AuthFailure.classify(status: 429, serverMessage: "Too many requests. See https://api.inventaire.io")` returns `.rateLimited`.
- [ ] `AuthFailure.classifySignup(status: 429, errorName: nil, serverMessage: …)` returns `.rateLimited`.
- [ ] `.rateLimited.signupField` is `nil`.
- [ ] `.rateLimited.message` is the catalogue key whose fr value is « Trop de tentatives. Réessayez dans quelques minutes. » and en value « Too many attempts. Try again in a few minutes. »
- [ ] 401 / 403 still → `.invalidCredentials`; 500 still → `.server` with « Une erreur est survenue. Réessayez plus tard. »
- [ ] Sign-in screen, server answering 429 → the new sentence under both fields.
- [ ] Unit tests in `Tests/AuthFailureTests.swift` cover the 429 mapping for both classifiers, next to the 401/403 ones.

## Implementation

- `ReCIT_iOS/Model/Authentication/AuthFailure.swift`: new `case rateLimited`; `classify` maps `429` onto it (`classifySignup` gets it through `classify`); `signupField` → `nil`; `message` → `auth.error.rate_limited`. File header: three failures told apart on screen, not two.
- `ReCIT_iOS/Localizable.xcstrings`: `auth.error.rate_limited` — fr « Trop de tentatives. Réessayez dans quelques minutes. », en « Too many attempts. Try again in a few minutes. »
- `ReCIT_iOS/Tests/AuthFailureTests.swift`: 4 tests — `classify` 429 (real server message and nil), `classifySignup` 429, `signupField` nil, message key distinct from generic / invalid credentials / network.
- No view change: `LoginView` and `CreateAccountView` only read `message` and `signupField`; the only exhaustive switches are in `AuthFailure.swift`.
- Lint: baseline matches by line text; the new test writes `.init(localized:)` so baselined copies of `let generic: String = String(localized: …)` keep matching. Baseline did not grow.
- Android `AuthFailure.kt` has the same gap: out of scope.
- Proof: build ✅ · `AuthFailureTests` 19/19 ✅.

## Review

### Round `validation` — 2026-11-06

Scope: `origin/main..wa/7-fix-rate-limited-sign-in-message`. LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓.

- 🟡 `AuthFailure.swift:21` — [style] edited header paragraph not wrapped like the rest → **fixed**.
- 🟡 `AuthFailure.swift:102` — [elegance] chain of `if status == …` returns → **fixed**: one `switch status` (`401, 403` / `429` / `default`).
- Round 2: ✅ review clean. Build ✅ · `AuthFailureTests` 19/19.
- Wiki: `docs/wiki/features/0083-rate-limited-sign-in-message.md`, a line in `claude.md` « Shipped features », `architecture.md` (Sessions), `account-and-profile.md`, a pointer in 0012.

## Verification

manual validation — not run by agent. Owed: sign-in screen on a real `429` shows the new sentence under both fields.

## Feedback
