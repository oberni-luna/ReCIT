---
issue: 70
status: todo
wiki: [[architecture]], [[adr/0008-session-login-signup-keychain]], [[account-and-profile]], [[features/0083-rate-limited-sign-in-message]]
note: Part of #62 (Ex-libris backend umbrella, decisions there). Blocked by #69 (skeleton). The domain used in e-mails is chosen with the hosting.
created: 2026-11-06
---

## Context / Decisions

> cookie-session, /api/auth/*, account emails
>
> Part of #62. inventaire:session + .sig reproduced, login/signup/logout/password/email-confirmation/reset-password, Mailpit.

The backend opens, checks and closes sessions exactly as inventaire.io does, so `AuthService`, `SessionCookie` and ADR 0008 work against it unchanged.

### Routes the apps call (read from `AuthService.swift`, `UserModel+Account.swift`, Android's auth service)

- `POST /api/auth/login`, `POST /api/auth/logout`, `POST /api/auth/signup`
- `GET /api/auth/username-availability`, `GET /api/auth/email-availability`
- `POST /api/auth/reset-password`, `POST /api/auth/email-confirmation`
- `PUT /api/auth/password`

### Decisions

1. **Session = inventaire.io's `cookie-session`** (checked on Codeberg, `server/controllers/auth/lib/session/user_session.ts`, 2026-08-21: Passport is gone, the cookie stays):
   - `inventaire:session` = base64url JSON `{"user":"<32 hex id>","timestamp":<epoch ms>}`, the payload `SessionCookie.swift` decodes;
   - `inventaire:session.sig` = keygrip HMAC of the cookie, under our `SESSION_SECRET` (a list, newest first, so the secret can rotate);
   - same max age as inventaire.io's `cookieMaxAge`, `HttpOnly`, `SameSite=Lax`, `Secure` outside local HTTP;
   - an anonymous session (`{"timestamp":…}`) handed to public calls, as inventaire.io does (#62 decision 9).
2. **Login accepts a username or an e-mail** (`acceptEmailAsUsername`), answers `{"ok":true}` and sets the session. A wrong pair answers `401`, which `AuthFailure.classify` reads as wrong credentials. An unconfirmed address does not block sign-in, as on inventaire.io.
3. **Signup opens its own session**, as inventaire.io's does, and sends the confirmation e-mail.
4. **Validation copied from inventaire.io** (`server/lib/regex.ts`, `server/models/validations/user.ts`):
   - username `^[\p{Letter}\p{Number}_]{2,20}$`, unique without regard to case, plus inventaire.io's reserved words list;
   - e-mail: inventaire.io's `Email` regex, unique without regard to case;
   - password: 8 to 256 characters.
5. **Error bodies the apps read**: status, `status_verbose`, `message`, `error_name` as inventaire.io sends them. Signup refusals carry `error_name` `invalid_username` / `invalid_email` / `invalid_password`, and a taken name or address carries the sentences `AuthFailure.classifySignup` matches (« username is already used », « email is already used », « reserved word »). The exact shape comes from fixtures captured on inventaire.io; this extends the `{status, status_verbose}` shape of #69 where inventaire.io's carries more.
6. **Passwords hashed with argon2id** (`password4j`, OWASP parameters: 19 MiB, 2 iterations). Nothing is imported from inventaire.io: the migration (#67) recreates each account from the password the reader types.
7. **E-mail links open two minimal HTML pages served by the backend**, FR or EN by the account's language:
   - `GET /confirm-email?token=…` confirms the address and says « Adresse confirmée. Vous pouvez revenir dans Ex-libris. »;
   - `GET /reset-password?token=…` shows a form (new password, twice), posted back to the same path;
   - tokens single-use, 24 h for confirmation and 1 h for reset, only their hash stored.
   Deep links (#65) can open the app instead later.
8. **E-mails**: confirmation and reset only, FR / EN by the account's language, sent to Mailpit locally. The production SMTP provider and the sender domain come with the hosting.
9. **Rate limits** (Ktor `RateLimit`, in memory, one instance), answering `429`, which the apps already show (feature 0083):
   - `login`: 10 a minute per IP, 5 a minute per identifier;
   - `signup`: 5 an hour per IP;
   - `reset-password`, `email-confirmation`: 3 an hour per address.
10. **Where it lives**: `auth` package (`Routes.kt`, `Service.kt`, `Repository.kt`), the `users` table created here with the columns sign-in needs (`_id`, `version`, username, e-mail, password hash, language, e-mail validated, created); #71 adds the profile.

### Out of scope

- `DELETE /api/user` (account deletion) → #71, with the rest of `/api/user`.
- `GET /api/auth/wikidata-oauth` (feature 0070) → not in this sprint; linking Wikidata serves bibliographic writes, to revisit with #77.
- Sign in with Apple / Google, two-factor.

## Acceptance criteria

- `POST /api/auth/signup` with a valid username, e-mail and password → `200`, `Set-Cookie: inventaire:session=…` whose payload names the new user, and a confirmation e-mail in Mailpit.
- Signup with a taken username, a taken e-mail, a 1-character username, a malformed e-mail or a 7-character password → `400` with the `error_name` or `message` `AuthFailure.classifySignup` maps to the right field.
- `GET /api/auth/username-availability?username=…` and `email-availability?email=…` answer as inventaire.io's fixtures, taken and free.
- `POST /api/auth/login` with the username, then with the e-mail → `200 {"ok":true}` and a user session; with a wrong password → `401`.
- An 11th login in a minute from one IP → `429`.
- A tampered `inventaire:session.sig` → the request is anonymous.
- `POST /api/auth/logout` → the session no longer names a user.
- `PUT /api/auth/password` with the right current password changes it; with a wrong one → the refusal `PasswordChangeFailure` reads; the session survives.
- Reset: `POST /api/auth/reset-password` → e-mail in Mailpit; its link opens the form; a new password saved there signs in; the same link a second time is refused.
- Confirmation: the link in the signup e-mail opens « Adresse confirmée… » and `/api/user` then reports the address validated.
- The iOS debug build with `-ExLibrisBackend http://localhost:8080`: Créer un compte, quit and relaunch (still signed in), Se déconnecter, Se connecter, all against the local backend.
- The same on Android with `-e exLibrisBackend http://10.0.2.2:8080`.
- Each route has a backend test against a fixture captured on inventaire.io.
