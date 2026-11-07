---
issue: 67
status: todo
wiki: [[architecture]], [[adr/0008-session-login-signup-keychain]], [[account-and-profile]], [[network]], [[features/0011-ex-libris-pre-login-onboarding]], [[features/0083-rate-limited-sign-in-message]]
note: Part of #62 (umbrella: « nothing ships to users before the migration », decision 8 keeps inventaire.io's `_id`s). Blocked by #75 (last of the parity tables: users, relations, groups, items, shelves, lists, transactions) and #93 (a hosted backend the released apps point at). If #77 has landed, imported users get their `anonymizable_id` like any other. iOS + Android in this task.
created: 2026-11-07
---

## Context / Decisions

> inventaire.io accounts moved to Ex-libris at launch
>
> Après upgrade : à la première ouverture de l'App les comptes sont migrés de inventaire.io au backend ex-libris (en demandant aux users leur mot de passe pour pouvoir recréer le compte de notre côté).

The first version of the apps on the Ex-libris backend moves each reader's inventaire.io account there: profile, books, étagères, lists, friends, groups and transactions, under the same ids, with the reader's password.

1. **The app signs in to inventaire.io, the backend reads.** The migration screen asks for the password. The app itself calls `POST https://inventaire.io/api/auth/login` (from the phone's IP, so inventaire.io's per-IP sign-in limit is never hit by the server; a `429` shows 0083's sentence), which proves the password and gives a fresh inventaire.io session. The app then sends the backend `POST /api/auth/migrate` `{ password, session: { "inventaire:session", "inventaire:session.sig" } }`. The backend reads the account from inventaire.io **with that session only** — it never signs in to inventaire.io and never writes to it — and creates the Ex-libris account with that password (hashed as in #70). The answer opens an Ex-libris session (same cookies as `/api/auth/login`). The app then forgets the inventaire.io session (in `AuthService` only, ADR 0008).
2. **What is read and kept, ids unchanged**: the user document (username, bio, picture copied into our image store, position, language, settings, e-mail and its `validEmail`), every item (with private notes, details, visibility, transaction mode), étagères with their items, lists with elements and comments, relations (friends, invitations sent and received), groups the reader belongs to (document, members, admins, invitations, requests, picture), transactions with their messages. Pagination as inventaire.io serves it. One database transaction: a failure creates nothing, and the screen offers « Réessayer ».
3. **People not (yet) on Ex-libris are reserved, dormant.** Every user the reader's data names — a friend, an inviter, a group member, the other side of a transaction — who has no Ex-libris account gets a **reserved** user row: same `_id`, username and picture, no password, no e-mail. A reserved user cannot sign in, is never returned by search, profiles, relations, groups' member lists or transactions: every relation, membership or transaction involving them stays stored and invisible. When that person migrates, their row becomes a real account, their own data is imported over it (their side wins), and what was dormant appears. A reserved username cannot be taken at sign-up (`400 username already exists`, as today).
4. **Once per account.** `POST /api/auth/migrate` on a user that is already a real Ex-libris account answers `409 already migrated`; the screen says « Ce compte est déjà sur Ex-libris » and opens « Se connecter ». A username taken by someone who signed up natively on Ex-libris answers `409 username taken`, and the screen asks for another username before retrying.
5. **inventaire.io is left as it is.** Nothing is deleted or changed there; the account keeps working on the inventaire.io site and diverges from then on. Contributions made on inventaire.io before the move stay under the inventaire.io account (see #77).
6. **When it is offered.**
   - **After the update**, a reader who has an inventaire.io session and no Ex-libris session sees a full-screen « Transfert de compte », before anything else: « Ex-libris a maintenant son propre serveur. Pour continuer, transférez votre compte : vos livres, étagères, listes, ami·es, groupes et échanges vous suivent. Votre compte inventaire.io reste tel quel. », the username shown, a password field, the primary « Transférer mon compte », and « Se déconnecter » as the only other way out. A progress state while it runs.
   - **On a new install**, « Se connecter » offers « J'ai un compte inventaire.io », which opens the same screen with the username field editable.
   - A wrong password: « Mot de passe incorrect » under the field, from inventaire.io's `401`.
7. **Release switch.** `Env.production`'s base URL becomes the hosted backend (#93); inventaire.io's URL stays in `Env` for the migration sign-in and the relayed bibliography only. `-ExLibrisBackend` keeps working for local runs.
8. **Where it lives.** Backend: an `auth/migration` package (`MigrationRoutes`, `MigrationService`, `InventaireAccountReader` over the user's session, `ReservedUsers`); a `reserved` flag on `users` in the next free Flyway migration, read by the users, relations, groups, search and transactions repositories. iOS: `Features/Authentication/` (migration screen, the entry from « Se connecter »), the pure outcome type in `Model/Authentication/` (`MigrationFailure`, on the pattern of `AuthFailure`), the session handover in `AuthService`. Android: the same in its authentication feature.

### Out of scope

- Deleting or changing anything on inventaire.io, now or later.
- Importing friends' books for a friend who has not migrated (they come with that friend).
- Notifications, inventaire.io activity history, contributions.
- A second import to refresh an account already moved.

## Acceptance criteria

Against a stub of inventaire.io serving fixtures (never the real inventaire.io with an account; one real move of Olivier's own test account, by Olivier, after #93):

- iOS, an install signed in to inventaire.io, relaunched on the Ex-libris backend: « Transfert de compte » appears before the Inventaire; with the right password, « Transférer mon compte » ends on the Inventaire showing the account's books, étagères and lists; relaunched, it is still signed in, on the Ex-libris backend, with no inventaire.io session left.
- The backend's database then holds the user, items, shelves, lists, relations, groups and transactions of the fixture under inventaire.io's `_id`s, and the user signs in with that password at `POST /api/auth/login`.
- A friend in the fixture who has not migrated is not in Réseau, not found by Recherche, and their group membership is not shown; signing up as that friend's username answers « username already exists ». Migrating that friend next makes the friendship appear on both accounts.
- A wrong password shows « Mot de passe incorrect » and creates nothing; a stub that fails halfway leaves no row and the screen offers « Réessayer ».
- Migrating the same account twice: the second time shows « Ce compte est déjà sur Ex-libris » and opens « Se connecter ».
- A new install: « Se connecter › J'ai un compte inventaire.io » with username and password ends signed in, same result.
- « Se déconnecter » on the transfer screen returns to the welcome screen, nothing created.
- The same journeys on Android.
- The backend never calls `/api/auth/login` on inventaire.io, and no request it sends to inventaire.io during a migration is other than a `GET` (stub log).
