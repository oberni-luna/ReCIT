---
issue: 93
status: todo
wiki: [[architecture]]
note: Part of #62 (umbrella decisions 2 and 11). Blocks #77 (inventaire.io must reach the actor key and by-anonymizable-ids over public HTTPS) and #67 (the released apps point at the hosted backend). Backups split to #110. Probed 2026-11-09 over SSH (key ~/.ssh/exlibris_vps, user debian, passwordless sudo) — read-only, nothing changed on the server during the grill.
created: 2026-11-09
---

## Context / Decisions

> Ex-libris runs online over HTTPS
>
> Split from #77 grill. Covers domain + TLS, deploy of the compose stack, secrets, Postgres backups, SMTP provider for account e-mails.

The Ex-libris backend runs on the internet, at `https://exlibris.lunabee.ovh`, so the apps and inventaire.io can reach it.

1. **Where: the OVH VPS 37.59.107.30**, reached with `ssh -i ~/.ssh/exlibris_vps debian@37.59.107.30` (Debian 12, 8 cores, 22 GB, 197 GB disk, Docker 29, Compose 5). **The server is shared**: the host's nginx holds 80/443 and already serves onesafe, plane, empreinte, casier and domo, each a Compose project bound to `127.0.0.1:86x0`, each with its own Let's Encrypt certificate. Ex-libris follows that convention and touches nothing else: its own Compose project, its own directory, one new nginx site file. No other project's container, file, network or config is read or changed.
2. **Domain: `exlibris.lunabee.ovh`**, Lunabee's convention for projects in progress (listed on `home.lunabee.ovh`). The `*.lunabee.ovh` wildcard already resolves to the VPS: no DNS record to add for the site. A dedicated domain comes later; everything that names the host reads `PUBLIC_BASE_URL`, so the switch is a config change (the deep links of #65 will be tied to whichever domain they ship with).
3. **The stack.** `Recit_Backend/docker-compose.prod.yml`, project name `exlibris`: `db` (`postgres:17`, volume `exlibris-db`, no published port) and `backend` (built from `Recit_Backend/Dockerfile`, volume `exlibris-images` at `/data/images`, published on `127.0.0.1:8630` only). No Mailpit. `restart: unless-stopped`, the `/health` healthcheck kept, Docker's `json-file` logs capped (`max-size 10m`, `max-file 5`).
4. **nginx + TLS.** `/etc/nginx/sites-available/exlibris.lunabee.ovh` (enabled by symlink): proxy to `127.0.0.1:8630` with `Host`, `X-Forwarded-For`, `X-Forwarded-Proto`; `client_max_body_size 10m` for image uploads; HTTP redirected to HTTPS. Certificate from Let's Encrypt with certbot, as the other sites. `nginx -t` must pass before every reload; a failing test leaves the running config alone.
5. **Deploy: `scripts/deploy-backend.sh`, run from the Mac** by Olivier, or by Claude when asked. It takes a pushed commit (default: `origin/main`), sends its `Recit_Backend/` with `git archive` to `/srv/exlibris/` on the VPS, runs `docker compose -p exlibris -f docker-compose.prod.yml up -d --build`, waits for `https://exlibris.lunabee.ovh/health`, and prints the deployed commit, also written to `/srv/exlibris/DEPLOYED`. Volumes survive every deploy. A first-run mode creates `/srv/exlibris`, the `.env` and the nginx site, and asks certbot for the certificate. No CI for now.
6. **Secrets live in `/srv/exlibris/.env`** (owner `debian`, mode `600`), never in git: `POSTGRES_PASSWORD` and the session secret generated on the server at first run (`openssl rand`), `PUBLIC_BASE_URL=https://exlibris.lunabee.ovh`, `INVENTAIRE_BASE_URL=https://inventaire.io`, the SMTP settings. `#77` adds `FEDERATION_PRIVATE_KEY` there. `Recit_Backend/.env.example` gains the production keys, with no values.
7. **E-mails: Brevo** (umbrella decision 11). SMTP relay `smtp-relay.brevo.com:587` with STARTTLS; sender `Ex-libris <no-reply@exlibris.lunabee.ovh>`. Olivier creates the Brevo account, puts the SMTP login and key in the server's `.env` himself, and adds Brevo's SPF and DKIM records to the `lunabee.ovh` zone at OVH; Claude never types them. The backend's SMTP config gains the port, STARTTLS and credentials it lacks today (Mailpit needed none).
8. **One instance, production.** No staging. Debug builds keep their local backend; any build can be pointed at the hosted one with `-ExLibrisBackend https://exlibris.lunabee.ovh` (iOS) or `-e exLibrisBackend https://exlibris.lunabee.ovh` (Android). Pointing the released apps at it is #67.
9. **Where it lives.** `Recit_Backend/docker-compose.prod.yml`, `Recit_Backend/deploy/nginx/exlibris.lunabee.ovh.conf` (the site file the script installs), `scripts/deploy-backend.sh`, the SMTP fields of the backend's config, a `docs/wiki/integrations/hosting.md` page (server, layout, deploy, secrets' names, how to read the logs).

### Out of scope

- Backups: #110.
- Monitoring and alerts beyond Docker's restart policy and the healthcheck.
- CI deployment, a staging instance, a dedicated domain.
- Adding Ex-libris to `home.lunabee.ovh`.

## Acceptance criteria

- `curl -i https://exlibris.lunabee.ovh/health` answers `200` over a valid Let's Encrypt certificate; `http://exlibris.lunabee.ovh/health` redirects to HTTPS.
- `ssh debian@37.59.107.30 'ss -tlnp'` shows the backend on `127.0.0.1:8630` only, and Postgres on no host port.
- The iOS app launched with `-ExLibrisBackend https://exlibris.lunabee.ovh` signs up a new test account, survives a relaunch signed in, and signs out; the confirmation e-mail sent by Brevo reaches a real inbox from `no-reply@exlibris.lunabee.ovh`, passing SPF and DKIM.
- The same sign-up on Android with `-e exLibrisBackend https://exlibris.lunabee.ovh`.
- An avatar uploaded from the Profil is served back at `https://exlibris.lunabee.ovh/img/users/<hash>`.
- `scripts/deploy-backend.sh` run a second time on a newer commit keeps the test account and its avatar, and `/srv/exlibris/DEPLOYED` names the new commit.
- After the first deploy, `sudo nginx -t` passes and the other sites (`home.lunabee.ovh` and the project sites it lists) still answer as before.
- `/srv/exlibris/.env` is mode `600` and no secret is in the repository.
