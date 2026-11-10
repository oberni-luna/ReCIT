# Hosting the Ex-libris backend

Where `Recit_Backend/` runs on the internet, at `https://exlibris.lunabee.ovh`, and how it gets there.
Decided in task #93; backups are #110.

## The server

Lunabee's OVH VPS, `37.59.107.30` (Debian 12, Docker, Compose). It is **shared**: the host's nginx holds
ports 80 and 443 and already serves Lunabee's other projects (`home.lunabee.ovh` lists them), each a Compose
project bound to `127.0.0.1:86x0` with its own Let's Encrypt certificate. Ex-libris follows that convention and
touches nothing of theirs: no other project's container, volume, directory or site file is read or changed.

The `*.lunabee.ovh` wildcard already resolves to the VPS, over IPv4 and IPv6: no DNS record was added for the
site. A dedicated domain comes later; everything that names the host reads `PUBLIC_BASE_URL`.

Access: `ssh -i ~/.ssh/exlibris_vps debian@37.59.107.30`. The `debian` user has passwordless sudo.

## Layout

| What | Where |
|---|---|
| The deployed `Recit_Backend/` | `/opt/exlibris/app` (owner `debian`, directory mode `750`) |
| The one before it | `/opt/exlibris/app.previous` |
| Secrets and settings | `/opt/exlibris/.env`, mode `600`, never in git |
| What was deployed, and when | `/opt/exlibris/DEPLOYED`, one line per deploy, `<sha> <UTC date> <ref>`, the last is live |
| Compose project | `exlibris`, from `Recit_Backend/docker-compose.prod.yml`: `db` (Postgres 17) and `backend` |
| Volumes | `exlibris-db` (Postgres), `exlibris-images` (avatars, group photos); they survive every deploy |
| Port | `127.0.0.1:8630` → the backend's `8080`; Postgres publishes no port |
| nginx site | `/etc/nginx/sites-available/exlibris.lunabee.ovh`, enabled as `sites-enabled/zz-exlibris.lunabee.ovh` |
| Certificate | `/etc/letsencrypt/live/exlibris.lunabee.ovh/`, renewed by certbot's system timer |

The site file is `Recit_Backend/deploy/nginx/exlibris.lunabee.ovh.conf`: HTTP redirected to HTTPS, TLS 1.2 and
1.3, HSTS, `client_max_body_size 10m` for uploads, a proxy to `127.0.0.1:8630` passing `Host`, `X-Real-IP`,
`X-Forwarded-For` and `X-Forwarded-Proto`. The `zz-` prefix keeps it from becoming the server's default site, as
every sibling does. The redirect sits inside `location /` so certbot can add its challenge location next to it
when it renews. `exlibris.lunabee.ovh.bootstrap.conf`, port 80 only, is installed once, before the certificate
exists.

The backend reads the client's IP from nginx's `X-Forwarded-For`, its last value: the one nginx appends
(`XForwardedHeaders { useLastProxy() }`, `plugins/ForwardedHeaders.kt`). The values before it come from the client
and are not trusted. The per-IP sign-in and sign-up limits count that IP; without it, every client would share
the bucket of Docker's gateway.

Both containers restart `unless-stopped`; the backend's healthcheck is `/health`. Docker's `json-file` logs are
capped at five files of 10 MB per container.

## Deploying

From the Mac, in the repository:

```sh
scripts/deploy-backend.sh --setup     # once: directory, .env, nginx site, certificate, then a deploy
scripts/deploy-backend.sh             # deploys origin/main
scripts/deploy-backend.sh <ref>       # any commit already on an origin/* branch
```

The script refuses a commit that is not pushed. It sends the commit's `Recit_Backend/` with `git archive` into
`/opt/exlibris/app` (the previous one becomes `app.previous`), runs
`docker compose -p exlibris … up -d --build --remove-orphans`, waits up to three minutes for
`https://exlibris.lunabee.ovh/health`, and appends the deployed commit to `DEPLOYED`. If the backend does not
answer, it prints its last 80 log lines and stops.

`--setup` can be rerun. It never overwrites an existing `.env`. It asks certbot for a certificate only when there
is none. It installs a site file only after `nginx -t` passes, and puts the previous one back otherwise, without
reloading nginx. It stops if something other than Ex-libris already listens on `127.0.0.1:8630`. Overrides:
`EXLIBRIS_SSH`, `EXLIBRIS_SSH_KEY`, `EXLIBRIS_HOST`, `EXLIBRIS_DIR`.

There is no CI deployment and no staging: one instance, production.

### Rolling back

Deploy the commit before: `scripts/deploy-backend.sh <sha>`, with the sha from the line before the last in
`/opt/exlibris/DEPLOYED`. A rollback rebuilds from git, not from `app.previous`, which is kept to compare. A
Flyway migration already applied stays applied: rolling back past a schema change needs a look at the database
first.

## Logs

```sh
ssh -i ~/.ssh/exlibris_vps debian@37.59.107.30 \
  'docker compose -p exlibris -f /opt/exlibris/app/docker-compose.prod.yml --env-file /opt/exlibris/.env logs -f backend'
```

## Secrets

In `/opt/exlibris/.env`, by name only (`Recit_Backend/.env.example` lists them with no value):

- `POSTGRES_PASSWORD`, `SESSION_SECRET` — generated on the server by `--setup` with `openssl rand -hex 32`; they
  never leave it. To rotate the session secret, prepend a new one, comma-separated: the first signs, every one
  verifies.
- `PUBLIC_BASE_URL`, `INVENTAIRE_BASE_URL` — not secret, set by `--setup`.
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_STARTTLS`, `MAIL_FROM` — Brevo's relay, set by `--setup`.
- `SMTP_USER`, `SMTP_PASSWORD` — Brevo's SMTP login and key, filled by Olivier, then a deploy to apply them:
  `ssh -t -i ~/.ssh/exlibris_vps debian@37.59.107.30 'nano /opt/exlibris/.env'`.
- `FEDERATION_PRIVATE_KEY` — added by #77.

The backend refuses its development session secret when `PUBLIC_BASE_URL` is `https`.

## E-mails

Brevo's SMTP relay, `smtp-relay.brevo.com:587` with STARTTLS, from `Ex-libris <no-reply@exlibris.lunabee.ovh>`.
Olivier owns the Brevo account and adds its SPF and DKIM records to the `lunabee.ovh` zone at OVH. Until
`SMTP_USER` and `SMTP_PASSWORD` are filled, no account e-mail leaves.

## Backups

None yet: #110.
