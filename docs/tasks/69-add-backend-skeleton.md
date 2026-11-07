---
issue: 69
status: todo
wiki: [[architecture]], [[testing]], [[android]]
note: BLOCKED — Docker (OrbStack) not set up, compose and Testcontainers proofs not run. Part of #62 (Ex-libris backend umbrella, decisions there). First task of the sprint; #70 and #76 build on it.
created: 2026-11-06
---

## Context / Decisions

> Ktor, Postgres, Flyway, Compose, lint, launch argument
>
> Part of #62. Recit_Backend/, docker compose (Postgres, Mailpit), ktlint + detekt, docs/conventions/kotlin-backend.md, -ExLibrisBackend launch argument on iOS and Android.

The empty backend every other task of the sprint fills, and the switch that points the apps at it. No business route here. The stack and the API rules are #62's decisions (Kotlin + Ktor + PostgreSQL, Exposed + Flyway, one package per domain, inventaire.io's API reproduced).

### Prerequisite

- **OrbStack** provides `docker` and `docker compose` on this Mac (installed 2026-11-06 with `brew install --cask orbstack`, personal use; the app must be opened once to finish setup). Docker was not installed before.

### Decisions

1. **A standalone Gradle project in `Recit_Backend/`**: its own wrapper and `gradle/libs.versions.toml`, nothing shared with `Recit_Android/`. JDK 21, Kotlin 2.x, Ktor 3.x, Netty engine.
2. **Dependencies wired by hand** in one `AppContainer.kt` (repositories → services → routes), read by `Application.module()`. Same shape as `Recit_Android`'s `AppContainer.kt`; no DI framework.
3. **Running it locally, one Compose file, two ways**:
   - `docker compose up` — Postgres 17, Mailpit and the backend, built by a multi-stage `Dockerfile` (Ktor fat jar on `eclipse-temurin:21-jre`);
   - `docker compose up db mail` then `./gradlew run` — to iterate without rebuilding the image, Ktor development mode on.
   - Configuration from environment variables (`DATABASE_URL`, `SESSION_SECRET`, `SMTP_*`…) read by `application.conf`; `.env.example` committed, `.env` git-ignored.
4. **What the skeleton serves**:
   - `GET /health` → `200 {"status":"ok","db":"ok"}`, the database actually queried; the Compose healthcheck uses it;
   - any other path → `404 {"status":404,"status_verbose":"not found"}`;
   - one error handler (Ktor `StatusPages`) giving every error code that shape, the one the apps read (`status_verbose` is matched in the iOS password and merge errors);
   - one log line per request: method, path, status, duration.
5. **Flyway wired**, migrations in `src/main/resources/db/migration/`, run at start; `V1__init.sql` only enables `pg_trgm` (reader search, #71).
6. **Lint fails the build**: ktlint + detekt run by `./gradlew build`, every violation an error, no `@Suppress` to silence a rule — as SwiftLint on iOS.
7. **Tests**: Ktor `testApplication` + Testcontainers Postgres, covering `/health` and the `404` shape. No CI: the repository has none.
8. **The apps switch by a launch argument, debug builds only**:
   - **iOS**: `-ExLibrisBackend http://localhost:8080`, read through `UserDefaults` (arguments domain) by `Env.apiBaseUrl`, ignored in release. ATS gets `NSAllowsLocalNetworking` in `ReCIT-iOS-Info.plist`: it opens plain HTTP to local addresses only.
   - **Android**: an intent extra `exLibrisBackend` (`adb shell am start … -e exLibrisBackend http://10.0.2.2:8080`), read before `AppContainer` is built, replacing `ApiService.BASE_URL`; a debug-only `network_security_config` allows cleartext to `10.0.2.2` and `localhost`.
   - **Both**: with the base URL overridden, the session store takes a `.exlibris` suffix (iOS `Env.keychainKey`, Android `SESSION_STORE_NAME`), so a local-backend session never overwrites the inventaire.io one, nor the reverse.
   - Without the argument, both apps behave exactly as today.
9. **Kotlin conventions module**: `docs/conventions/kotlin-backend.md` — domain packages with `Routes.kt` / `Service.kt` / `Repository.kt`, Exposed only in repositories, wiring only in `AppContainer.kt`, inventaire.io's paths, payloads and error shape kept, ktlint + detekt rules never silenced. Added to `review.modules` in `.whackagent/config.md` so wa-verifier judges Kotlin.
10. **`CLAUDE.md` gets a Backend section**: where it lives, the two ways to run it, the launch argument on each app.

### Out of scope

- Any `/api/*` route (#70 onwards), the bibliography proxy (#76), hosting and deployment, CI.

## Acceptance criteria

- `docker compose up` in `Recit_Backend/` starts Postgres, Mailpit and the backend; `curl http://localhost:8080/health` → `200 {"status":"ok","db":"ok"}`.
- With Postgres stopped, `/health` answers a non-200 status in the `{"status":…,"status_verbose":…}` shape.
- `curl http://localhost:8080/api/whatever` → `404 {"status":404,"status_verbose":"not found"}`.
- Each request writes one log line with method, path, status and duration.
- `docker compose up db mail` then `./gradlew run` serves the same `/health`.
- `./gradlew build` runs ktlint, detekt and the tests; a deliberate lint violation fails it.
- The iOS debug build launched with `-ExLibrisBackend http://localhost:8080` sends its requests to the local backend (they appear in its log); launched without it, the app signs in and loads from inventaire.io as today.
- The Android debug build launched with `-e exLibrisBackend http://10.0.2.2:8080` sends its requests to the local backend; launched without it, unchanged.
- An inventaire.io session survives a launch with the argument: relaunched without it, the app is still signed in.
- `docs/conventions/kotlin-backend.md` exists and is listed in `review.modules`; `CLAUDE.md` has the Backend section.

## Implementation

**Blocked — open question:** Docker never came up on this Mac (OrbStack installed, first-run setup not finished: no `~/.orbstack/bin/docker`, no `/var/run/docker.sock`). Finish OrbStack's setup, then run the three proofs below; nothing else is missing.

1. `cd Recit_Backend && JAVA_HOME=/opt/homebrew/Cellar/openjdk@21/21.0.13.0.3/libexec/openjdk.jdk/Contents/Home ./gradlew build` — includes the 3 Testcontainers tests, which today fail only with `IllegalStateException` at `DockerClientProviderStrategy` (no Docker).
2. `docker compose up` then `curl localhost:8080/health` — first build of the `Dockerfile`; the backend healthcheck assumes `curl` exists in `eclipse-temurin:21-jre`.
3. `docker compose up db mail` then `./gradlew run`.

### What is built

- `Recit_Backend/`: standalone Gradle 9.7 project (Kotlin 2.4, Ktor 3.6 Netty, Exposed 1.6, Flyway 13, Hikari, Testcontainers 2), base package `studio.lunabee.exlibris.backend`. `Application.kt`, `AppContainer.kt`; `plugins/` (StatusPages error shape `{status, status_verbose}`, `ApiException`, request logging, serialization); `db/` (Postgres + Flyway); `health/` (`HealthRoutes.kt`, `HealthService.kt`, `HealthRepository.kt`); `V1__init.sql` enables `pg_trgm`. `Dockerfile`, `docker-compose.yml` (Postgres 17, Mailpit, backend), `.env.example`.
- ktlint (`ktlint_official`, 120 columns) + detekt fail `./gradlew build`.
- iOS: `Env` reads the debug-only `-ExLibrisBackend` argument (`UserDefaults`), keychain key gets `.exlibris`; `ReCIT.swift` now hands `AuthService` `Env`'s URL and key (same strings as before without the argument); `NSAllowsLocalNetworking`; `Tests/EnvTests.swift`.
- Android: `BackendOverride` reads the `exLibrisBackend` extra (debug only) before the container, now `by lazy`; `ApiService.BASE_URL` is a getter on it; debug `network_security_config` for `10.0.2.2` / `localhost`; session store suffix; `BackendOverrideTest`.
- `docs/conventions/kotlin-backend.md`, `CLAUDE.md` Backend section, `kotlin-backend.md` in `review.modules`.

### Proof

- Backend `./gradlew build -x test`: green (compile, ktlint, detekt). A deliberate violation failed it (detekt MagicNumber/MayBeConst, ktlint), reverted.
- Run with `./gradlew run` against a throwaway Homebrew Postgres 14 (not 17, no Docker): Flyway applied v1, `pg_trgm` present; `/health` → `200 {"status":"ok","db":"ok"}`; `/api/whatever` → `404 {"status":404,"status_verbose":"not found"}`; Postgres stopped → `503 {"status":503,"status_verbose":"database unreachable"}` in 2 s, back to 200 after restart; one log line per request (`GET /health 503 2027ms`).
- iOS build + ReCIT_iOSTests green (EnvTests 2/2). On iPhone 17: with the argument, requests reach `http://localhost:8080` (backend logs `GET /api/user 404`); without it, `https://inventaire.io`; the inventaire.io session survives a launch with the argument.
- Android `:app:assembleDebug :app:testDebugUnitTest` green (BackendOverrideTest 2/2). No emulator: no Android runtime check.

### Notes

- **For #70:** under the argument the app reads as signed in without a local session: `AuthService.sessionCookies()` matches cookies by name, not host, so `adoptJarSession()` copies the inventaire.io cookie into the `.exlibris` entry. #70 must scope session cookies to the base URL's host (Android's `SessionCookieJar` to check too).
- File names are `<Domain>Routes.kt` / `Service` / `Repository` rather than bare `Routes.kt`: ktlint's `filename` rule, not silenced; `kotlin-backend.md` records it.
- `SESSION_SECRET` and `SMTP_*` are not in the config yet: they come with #70.
- A route throws `ApiException` rather than responding an error body, or StatusPages overwrites it.
- Switching backend on Android needs `am start -S` (only a process's first launch reads the extra).

## Verification

Partial — see Proof. Compose and Testcontainers not run (Docker missing); Android runtime not run (no emulator).
