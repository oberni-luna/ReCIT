---
issue: 62
status: todo
wiki: [[architecture]], [[adr/0008-session-login-signup-keychain]], [[network]], [[lists]], [[account-and-profile]]
note: Umbrella of the Ex-libris backend sprint, split into #69–#77. Account migration is #67, blocked by this one.
created: 2026-11-06
---

## Context / Decisions

> social features ours, bibliography via inventaire.io
>
> Je veux créer un nouveau backend pour ex-libris, qui assure toutes les fonctionnalités sociales de l'App, et qui délègue toutes les fonctionnalités liées à la bibliographie à inventaire.io. L'app n'appelle que le backend ex-libris.

Why: inventaire.io splits into a Social Core and an Entities Core (Codeberg issue #883, NLnet grant 2026-02). Ex-libris wants its own social layer (group lists #63, lender-declared loans #64, deep links #65, list element discussions #66) without waiting on inventaire.io's roadmap.

This task is an umbrella: it holds the decisions, and is done when #69–#77 are done. Nothing here is coded directly.

### Scope

- Parity only: the backend serves every social call the iOS and Android apps make today, and relays the bibliographic ones. Nothing more.
- Out of scope, each its own task: group lists #63, lender-declared loans #64, deep links #65, list element discussions #66, account migration #67, push notifications (with #66), notification e-mails, hosting and deployment.
- Nothing ships to users before the migration (#67).

### Decisions

1. **Bibliographic writes go through federation.** The backend is a Social Core instance for inventaire.io: it signs requests (draft-cavage HTTP signatures, `rsa-sha256`) and names the user in `x-remote-user`. inventaire.io fetches the key at the `keyId` URL from any host, so there is no allowlist to join; Maxime is told anyway. A remote user has `roles: []`, so a merge from Ex-libris always becomes a task on inventaire.io.
2. **Ops: Olivier, with Claude.** Development is local, on Docker Compose. Hosting is deferred; the OVH VPS (37.59.107.30, Debian 12 + Docker) is the candidate, not checked: no SSH key of this Mac is accepted there and the KVM console did not let us in.
3. **Stack: Kotlin + Ktor + PostgreSQL.** Lunabee knows Kotlin, Android already uses `kotlinx-serialization` + OkHttp, and a Ktor JVM fits a small VPS.
4. **Same API as inventaire.io for everything the apps call today**: same paths, payloads, error codes and session cookie. The apps switch by changing their base URL; `AuthService`, ADR 0008 and the DTOs stay as they are. New features add their own routes later.
5. **Monorepo**: the code lives in `Recit_Backend/`, next to `ReCIT_iOS/` and `Recit_Android/`.
6. **Bibliography is a pass-through proxy, no cache in v1**:
   - relayed to inventaire.io: `/api/entities/*` reads, `/api/data/*`, `/api/search` for entity types, `/img/entities/*` (covers), `/api/items/recent-public` (welcome cover wall; ours later);
   - ours: `/img/users/*`, `/img/groups/*`;
   - Wikimedia (`commons.wikimedia.org`) stays called directly by the apps.
   `AbsoluteImageURL.resolve` puts the base URL before every `/img/...` path, so with the new base URL every such image reaches the backend.
7. **Signed bibliographic writes are #77**, built and tested later. Until then `create`, `update-claim`, `merge`, `resolve` and cover uploads answer an error. #77 also publishes the actor key and `/api/users?action=by-anonymizable-ids`, which inventaire.io calls to name contributors, at a public HTTPS URL.
8. **Ids in inventaire's shape**: `_id` is 32 hex characters (what `isUserId` accepts for `x-remote-user`), `_rev` is computed from a `version` column (`"3-<hash>"`). The apps only store `_rev`, never send it back. The migration (#67) keeps inventaire.io's `_id`s, so stores and links stay valid.
9. **Session: `cookie-session` reproduced exactly.** Two cookies, `inventaire:session` (base64url JSON `{"user","timestamp"}`, which `SessionCookie.swift` decodes to answer `isLoggedIn()`) and `inventaire:session.sig` (keygrip HMAC), under our own secret; an anonymous session handed to public calls, as inventaire.io does; the same `/api/auth/*` routes.
10. **`/api/search` split by `types`**: `users` and `groups` searched in Postgres (`pg_trgm`), entity types relayed to inventaire.io. A request mixing both worlds answers `400`; the apps never send one.
11. **E-mails: account only** — address confirmation and password reset, sent to Mailpit locally, through an SMTP provider chosen with the hosting. The « Notifications par e-mail » settings (feature 0055) are stored and do nothing until a later task.
12. **Parity is proven twice**:
    - backend tests: Ktor `testApplication` + Testcontainers Postgres, each endpoint's JSON compared to a fixture captured on inventaire.io (keys, types, error codes);
    - the apps on the local backend: a launch argument `-ExLibrisBackend http://localhost:8080` replaces the base URL in `Env` on iOS and Android, and Claude walks the journeys on the simulator. The e2e scenario stays run by Olivier only.
13. **Persistence: Exposed + Flyway**, migrations in plain SQL, replayed at start and in Testcontainers.
14. **One package per domain** — `auth`, `users`, `relations`, `groups`, `items`, `shelves`, `lists`, `transactions`, `search`, `entities` (proxy), `images` — each with `Routes.kt`, `Service.kt`, `Repository.kt`. ktlint + detekt fail the build, no `@Suppress` to silence a rule. A `docs/conventions/kotlin-backend.md` module is added so wa-verifier judges Kotlin.
15. **Images on disk**, in a Docker volume behind an `ImageStore` interface, files named by hash as `/img/users/<hash>`. S3 only if there is ever more than one server.

### Split

Sprint **Ex-libris backend**:

- #69 Add backend skeleton — Ktor, Postgres, Flyway, Compose, lint, launch argument
- #70 Add backend sign-in — blocked by #69
- #71 Add backend users and friends — blocked by #70
- #72 Add backend groups — blocked by #71
- #73 Add backend books and shelves — blocked by #71
- #74 Add backend lists — blocked by #73
- #75 Add backend transactions — blocked by #73
- #76 Add bibliography proxy — blocked by #69
- #77 Add signed bibliographic writes — blocked by #76

## Acceptance criteria

- `docker compose up` in `Recit_Backend/` starts Postgres, Mailpit and the backend on `http://localhost:8080`.
- The iOS app launched with `-ExLibrisBackend http://localhost:8080` signs up, signs in, survives a relaunch signed in, and signs out against the local backend.
- On that build, Inventaire, Listes, Réseau (Amis | Groupes), Recherche, Profil and an Échange load and write through the local backend.
- The same holds for the Android app launched with the same argument.
- On that build, no request leaves for inventaire.io; only `commons.wikimedia.org` is called besides the backend (seen in the network log).
- Every endpoint the apps call has a backend test comparing its JSON to a fixture captured on inventaire.io.
- #69–#77 are done.
