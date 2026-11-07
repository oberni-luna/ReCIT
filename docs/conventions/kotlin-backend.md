# Kotlin — Backend (`Recit_Backend/`)

> Project convention module, written for #69 from the decisions of #62. Reviewer: **conventions**. Applies to every Kotlin file under `Recit_Backend/`; the Swift modules do not. `CLAUDE.md` wins over this file.

## Layout

One package per domain under `studio.lunabee.exlibris.backend`: `auth`, `users`, `relations`, `groups`, `items`, `shelves`, `lists`, `transactions`, `search`, `entities` (the inventaire.io proxy), `images`. `health` is the first.

Each domain holds three roles, one file each, named after the domain (ktlint's `filename` rule):

| File | Holds | May use |
|---|---|---|
| `<Domain>Routes.kt` | `fun Route.<domain>Routes(service)`: paths, parameters, `call.respond` | its service, Ktor |
| `<Domain>Service.kt` | the rules: validation, permissions, what an answer is | its repository and other services |
| `<Domain>Repository.kt` | reads and writes, Exposed tables and queries | Exposed, JDBC |

- A payload or answer is a `@Serializable data class` in its own file, named after it (`HealthReport.kt`).
- **Exposed only in repositories.** No `transaction {}`, table or `ResultRow` in a service or a route.
- A repository function is `suspend` and runs its JDBC work in `withContext(Dispatchers.IO)`: Netty's event loop never blocks.
- Cross-cutting Ktor plugins live in `plugins/`, database plumbing in `db/`.

## Wiring

- **Only `AppContainer.kt` builds** repositories and services, by hand, in dependency order (repositories → services), as `Recit_Android`'s `AppContainer`. No DI framework, no service locator.
- `Application.module()` builds the container, installs the plugins, mounts each domain's routes with the service the container holds.
- Dependencies are constructor parameters. No `lateinit` for a dependency, no `object` holding mutable state.
- An interface only when a second implementation exists (a test fake counts). One implementation → the class itself.

## API parity with inventaire.io

Decision 4 of #62: the apps switch by base URL alone.

- Same paths, query parameters, payloads, status codes and session cookie as inventaire.io. A key renamed, dropped or retyped breaks a DTO the apps already decode.
- Verify a contract against inventaire.io's live OpenAPI spec or its Codeberg source, never the archived GitHub mirror.
- **Every error leaves as `ErrorBody`** — `{"status":<int>,"status_verbose":"<text>"}`. A service throws `ApiException(status, verbose)`; `StatusPages` writes it. A route never responds an error body itself: the status handler would replace it.
- Keep inventaire.io's `status_verbose` wording where the apps match on it (password and merge errors on iOS).

## Persistence

- Flyway migrations in plain SQL, `src/main/resources/db/migration/V<n>__<what>.sql`, replayed at start and in every test.
- A migration that has run anywhere is never edited: the next change is a new version.
- Ids keep inventaire.io's shape (#62 decision 8): `_id` 32 hex characters, `_rev` derived from a `version` column.

## Configuration

- `application.conf` reads each setting from an environment variable (`${?DATABASE_URL}`) over a default that works with `docker compose up db mail`.
- Every variable is listed in `.env.example`. `.env` is never committed; no secret in a committed file.

## Kotlin idioms

- `val` over `var`; immutable `data class` for values; `enum` or `sealed interface` for closed sets.
- Nullable over sentinels (`-1`, `""`). No `!!`: `requireNotNull`, `?:`, `?.let`.
- Errors as exceptions a `StatusPages` handler maps, or as a sealed result a service returns. Never a swallowed `catch`: log it, or let it reach `StatusPages`.
- Catch the narrowest type (`SQLException`, not `Exception`).
- Logging through SLF4J, one `Logger` per class in a `private companion object`. Never `println`.
- KDoc on what a name cannot say: the why, the inventaire.io behaviour reproduced. No comment narrating the code, no `TODO`.

## Lint

- `./gradlew build` runs ktlint (`ktlint_official`, `.editorconfig`) and detekt (default rules); every violation fails it, as SwiftLint on iOS.
- `./gradlew ktlintFormat` autofixes before a build.
- **Never silence a rule**: no `@Suppress`, no `ktlint-disable`, no baseline, no edit to `.editorconfig` or a detekt config to make a violation pass. A rule that cannot be met → ask.

## Tests

- JUnit 5 with `kotlin.test` assertions. Test names in backticks, saying the behaviour.
- A route is tested through Ktor's `testApplication`: `environment { config = TestPostgres.config(postgres) }`, then `application { module() }` — the real wiring, not a hand-built router.
- The database is a Testcontainers `postgres:17`, the image Compose runs. Never H2, never a mocked repository for a route test.
- Parity tests compare the whole JSON body with a fixture captured on inventaire.io (keys, types, error codes), as #62 decision 12 asks.

## Review checklist (Kotlin backend)

- Exposed, `transaction` or SQL outside a repository → finding.
- A repository or service built outside `AppContainer.kt` → finding.
- An error body written by a route, or not in `ErrorBody`'s shape → finding.
- A path, key or status differing from inventaire.io for a call the apps make → critical.
- A migration that already ran, edited → critical.
- `@Suppress`, `ktlint-disable`, or a lint config loosened → critical.
- Blocking JDBC outside `Dispatchers.IO` → finding.
- A route test without `testApplication` + Testcontainers → finding.
