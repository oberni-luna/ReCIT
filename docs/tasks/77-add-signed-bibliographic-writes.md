---
issue: 77
status: todo
wiki: [[architecture]], [[features/0020-creating-a-book-that-inventaire-lacks]], [[features/0047-new-book-work-first]], [[features/0049-edit-an-edition]], [[features/0050-every-bibliographic-datum]], [[features/0051-edition-duplicates]], [[features/0057-edit-works-and-authors]], [[features/0070-wikidata-account-and-editing]], [[features/0087-book-creation-from-search]]
note: Part of #62 (Ex-libris backend umbrella, decisions 1 and 7). Blocked by #76 (bibliography proxy, which answers 501 for writes today) and #93 (hosting — inventaire.io must reach the actor key and by-anonymizable-ids over public HTTPS before the one real write). Verified on Codeberg 2026-11-07, server/lib/federation/remote_user.ts and server/controllers/activitypub/lib/security.ts.
created: 2026-11-07
---

## Context / Decisions

> signed writes for later, x-remote-user — Part of #62. HTTP signatures rsa-sha256, x-remote-user, public actor key, /api/users?action=by-anonymizable-ids.

The apps' bibliographic writes — creating a book, editing an edition, a work or an author, merging duplicates, uploading a cover — stop answering `501` on the Ex-libris backend and reach inventaire.io in the reader's name, through inventaire.io's federation.

1. **Mechanism (umbrella decision 1).** The backend relays each write to inventaire.io, signed with draft-cavage HTTP signatures (`rsa-sha256`, the headers inventaire.io's `security.ts` checks: `(request-target)`, `host`, `date`, `digest` on a body), and names the reader in `x-remote-user`. inventaire.io fetches the public key at the `keyId` URL; there is no allowlist. A remote user has `roles: []`: a merge always becomes a task on inventaire.io, never an immediate merge — the apps already handle « handed to inventaire.io's team » (0051).
2. **Which writes.** Exactly those whose inventaire.io controller goes through `parseReqLocalOrRemoteUser` and that the apps call: `POST /api/entities?action=create`, `PUT /api/entities?action=update-claim`, `PUT /api/entities?action=update-label`, `PUT /api/entities?action=merge`, `POST /api/entities?action=resolve` (with `create`/`update`), and the `entities` container of `POST /api/images?action=upload`. Same paths, same bodies, same answers as inventaire.io (fixtures as in #76); inventaire.io's refusals are relayed with their status and body. Recheck the list on Codeberg at coding time: a route that refuses a remote user keeps answering `501`.
3. **One instance key.** A single RSA key pair for the whole backend, as inventaire.io does for its own federated requests (« instance actor … to maximize key cache hits »). The private key comes from a deploy secret (`FEDERATION_PRIVATE_KEY`, PEM); locally, a key generated at first start into the compose volume. The public key is served at an actor URL under `PUBLIC_BASE_URL` (an ActivityPub actor document with `publicKey { id, owner, publicKeyPem }`, the `keyId` being `<actor>#main-key`). No rotation, no per-user keys.
4. **Who the reader is to inventaire.io.** `x-remote-user` carries the reader's **anonymizable id**, not their `_id`: users gain `anonymizable_id` (32 hex, random, set for existing rows by the migration, never exposed by the apps' APIs). inventaire.io records the contribution under `<anonymizableId>@<our host>`.
5. **Naming contributors.** The backend serves `GET /api/users?action=by-anonymizable-ids&ids=<id>|<id>` publicly, in inventaire.io's shape (fixture). A reader with `settings.contributions.anonymize` true (stored since #71, « Compte et connexion ») is returned anonymised, as inventaire.io does; otherwise username and picture. Unknown ids are absent from the answer.
6. **Wikidata entities stay out.** inventaire.io's `edit_wikidata` requires a local session, so a signed request cannot edit a Wikidata work or author. On the Ex-libris backend, `update-claim`/`update-label` on a `wd:` URI answer `501`. iOS hides « Modifier » on Wikidata works and authors and the « Compte et connexion › Wikidata » row when the base URL is not inventaire.io (as before 0070); everything stays as it is against inventaire.io. Android has no Wikidata editing: nothing to change.
7. **Proof.** Backend tests run against a **faithful stub** of inventaire.io: a small test server that verifies the signature with the same algorithm as `security.ts` (fetches the `keyId`, rebuilds the signing string, checks `date` freshness and `digest`), reads `x-remote-user`, calls back `by-anonymizable-ids`, and answers the fixture. A wrong key, a stale date or a tampered body is refused, as on inventaire.io. **One real write**, after #93, agreed with Maxime beforehand (a claim on a test edition, then reverted) — nothing else is ever written to inventaire.io in production by tests or by Claude.
8. **Where it lives.** Backend: a `federation` package (`FederationKey`, `RequestSigner`, `ActorRoutes`, `AnonymizableIdsRoutes`); `entities/EntitiesRoutes.kt` and `images/ImagesService.kt` replace their `notImplemented()` with a signed relay through `InventaireClient`; the next free Flyway migration adds `users.anonymizable_id`. iOS: the Wikidata gates in `Features/EntityBrowser/` and the Wikidata row of the profile's account screen read one predicate on `Env` (« talks to inventaire.io »).

### Out of scope

- Wikidata edits from Ex-libris (decision 6).
- Contributions made on inventaire.io before the migration (#67) stay under the inventaire.io account; they are not re-attributed.
- Key rotation, per-user keys, ActivityPub inboxes, `instances/subscribe` and `instances/events`.
- Entity deletion, label removal, merge revert, move to Wikidata: the apps do not call them.

## Acceptance criteria

- `GET <PUBLIC_BASE_URL>/<actor path>` answers an actor document whose `publicKey.publicKeyPem` verifies a signature made by the backend.
- Against the stub: the iOS app on `-ExLibrisBackend http://localhost:8080`, signed in, saves a change in « Modifier l'édition » on an inventaire.io edition; the stub receives `PUT /api/entities?action=update-claim` with a valid signature and `x-remote-user` equal to the reader's anonymizable id, and the app shows the saved value, with no `501`.
- Against the stub: « Nouveau livre » from the scanner publishes through `resolve`, and a photographed cover goes through `images?action=upload` signed; « Les comparer › Fusionner » ends on « handed to inventaire.io's team ».
- The stub refuses (and the backend relays the refusal of) a request signed with another key, a `date` older than inventaire.io's tolerance, or a body whose `digest` does not match.
- `GET /api/users?action=by-anonymizable-ids&ids=<a>|<b>` answers the reader `a` with username and picture, and the reader `b`, who turned on « Anonymiser mes contributions », anonymised; neither answer contains `_id` or e-mail.
- On the Ex-libris backend, a Wikidata work's and a Wikidata author's screens show no « Modifier », and « Compte et connexion » has no « Wikidata » row; on inventaire.io both are there as before.
- `update-claim` on a `wd:` URI answers `501`.
- After #93, one real `update-claim` agreed with Maxime lands on inventaire.io under `<anonymizableId>@<our host>` and is reverted.
