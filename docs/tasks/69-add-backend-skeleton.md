---
issue: 69
status: todo
wiki: [[architecture]], [[testing]], [[android]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). First task of the sprint; #70 and #76 build on it.
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
