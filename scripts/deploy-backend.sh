#!/usr/bin/env bash
# Deploys a pushed commit's Recit_Backend/ to the shared VPS, as the Compose project `exlibris` behind the
# host's nginx (#93). Read docs/wiki/integrations/hosting.md first.
#
#   scripts/deploy-backend.sh                    # deploys origin/main
#   scripts/deploy-backend.sh <ref>              # any ref whose commit is on an origin/* branch
#   scripts/deploy-backend.sh --setup [<ref>]    # first run: directory, .env, nginx site, certificate, then deploys
#
# Overrides: EXLIBRIS_SSH (debian@37.59.107.30), EXLIBRIS_SSH_KEY (~/.ssh/exlibris_vps),
# EXLIBRIS_HOST (exlibris.lunabee.ovh), EXLIBRIS_DIR (/opt/exlibris).
#
# The commit's Recit_Backend/ goes over ssh with `git archive` into $EXLIBRIS_DIR/app (the one before is kept as
# app.previous), Compose rebuilds and restarts it, the script waits for https://$EXLIBRIS_HOST/health and appends
# `<sha> <UTC date> <ref>` to $EXLIBRIS_DIR/DEPLOYED. The volumes survive every deploy. To roll back, deploy the
# previous sha that DEPLOYED lists.
#
# --setup can be rerun: it never overwrites an existing .env, and generates its secrets on the server, where they
# stay. It touches no other site, container, volume or directory; a site file that fails `nginx -t` is put back
# as it was, and nginx is not reloaded.

set -euo pipefail

usage() {
    sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

die() { printf 'deploy-backend: %s\n' "$*" >&2; exit 1; }

setup=false
ref=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --setup) setup=true ;;
        -*) usage >&2; exit 2 ;;
        *)
            [[ -z "$ref" ]] || { usage >&2; exit 2; }
            ref="$1"
            ;;
    esac
    shift
done
ref="${ref:-origin/main}"

ssh_target="${EXLIBRIS_SSH:-debian@37.59.107.30}"
ssh_key="${EXLIBRIS_SSH_KEY:-$HOME/.ssh/exlibris_vps}"
host="${EXLIBRIS_HOST:-exlibris.lunabee.ovh}"
dir="${EXLIBRIS_DIR:-/opt/exlibris}"
port=8630
project=exlibris

remote() {
    ssh -i "$ssh_key" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15 "$ssh_target" "$@"
}

# Helpers every remote step starts with. `dc` is docker without sudo when the ssh user may, sudo -n docker otherwise.
read -r -d '' remote_prelude <<'PRELUDE' || true
set -euo pipefail
die() { printf 'deploy-backend (server): %s\n' "$*" >&2; exit 1; }
dc() {
    if docker info >/dev/null 2>&1; then
        docker "$@"
    else
        sudo -n docker "$@"
    fi
}
# The project's Compose, from the deployed app/: `stack <dir> <project> up -d`.
stack() {
    local dir="$1" project="$2"
    shift 2
    dc compose -p "$project" -f "$dir/app/docker-compose.prod.yml" --env-file "$dir/.env" "$@"
}
PRELUDE

# Runs on the server the `main` function read from stdin (a quoted heredoc: nothing expands on the Mac), with the
# arguments given here. bash parses `main` whole before running it, so no command inside can eat the script.
remote_step() {
    {
        printf '%s\n' "$remote_prelude"
        cat
        printf '\nmain "$@"\n'
    } | remote "bash -s -- $(printf '%q ' "$@")"
}

repo="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)" || die "not inside the repository"
cd "$repo"

git fetch --quiet origin
sha="$(git rev-parse --verify --quiet "$ref^{commit}")" || die "unknown ref: $ref"
[[ -n "$(git branch -r --contains "$sha")" ]] || die "$ref ($sha) is on no origin/* branch: push it first"
printf 'Deploying %s (%s) to %s:%s\n' "$ref" "${sha:0:12}" "$ssh_target" "$dir"

if $setup; then
    printf '== Setup: %s, its .env, port %s\n' "$dir" "$port"
    remote_step "$dir" "$host" "$port" "$project" <<'STEP'
main() {
    local dir="$1" host="$2" port="$3" project="$4"
    sudo -n true 2>/dev/null || die "sudo asks for a password: --setup needs passwordless sudo"

    sudo -n install -d -o "$(id -un)" -g "$(id -gn)" -m 750 "$dir"

    if [ -e "$dir/.env" ]; then
        echo "$dir/.env exists: kept as it is"
    else
        local postgres_password session_secret tmp
        postgres_password="$(openssl rand -hex 32)"
        session_secret="$(openssl rand -hex 32)"
        tmp="$(mktemp "$dir/.env.XXXXXX")"
        chmod 600 "$tmp"
        cat >"$tmp" <<ENV
# Ex-libris backend (#93): read by docker compose --env-file, never in git.
# SMTP_USER and SMTP_PASSWORD are Brevo's SMTP login and key, filled by hand.
POSTGRES_PASSWORD=$postgres_password
SESSION_SECRET=$session_secret
PUBLIC_BASE_URL=https://$host
INVENTAIRE_BASE_URL=https://inventaire.io
SMTP_HOST=smtp-relay.brevo.com
SMTP_PORT=587
SMTP_STARTTLS=true
SMTP_USER=
SMTP_PASSWORD=
MAIL_FROM="Ex-libris <no-reply@$host>"
ENV
        mv "$tmp" "$dir/.env"
        echo "$dir/.env created, mode 600, secrets generated here"
    fi

    if [ -n "$(ss -Htln "sport = :$port")" ]; then
        dc ps --filter "label=com.docker.compose.project=$project" --format '{{.Ports}}' \
            | grep -q "127.0.0.1:$port->" \
            || die "127.0.0.1:$port is already listened to by something other than $project"
    fi
}
STEP
fi

remote_step "$dir" <<'STEP'
main() {
    [ -f "$1/.env" ] || die "$1/.env is missing: run scripts/deploy-backend.sh --setup first"
}
STEP

printf '== Sending Recit_Backend/ at %s\n' "${sha:0:12}"
qdir="$(printf '%q' "$dir")"
git archive --format=tar "$sha" Recit_Backend \
    | remote "set -euo pipefail; rm -rf $qdir/app.new; mkdir -p $qdir/app.new; tar -x -C $qdir/app.new --strip-components=1"

if $setup; then
    printf '== Setup: nginx site and certificate for %s\n' "$host"
    remote_step "$dir" "$host" <<'STEP'
# Installs one of the shipped site files as sites-available/<host>, enabled as sites-enabled/zz-<host>, and reloads
# nginx only if `nginx -t` passes. Otherwise puts back what was there and stops.
install_site() {
    local source="$1" host="$2"
    local available="/etc/nginx/sites-available/$host"
    local enabled="/etc/nginx/sites-enabled/zz-$host"
    local candidate backup="" linked=false

    candidate="$(mktemp)"
    sed "s/exlibris\.lunabee\.ovh/$host/g" "$source" >"$candidate"
    if sudo -n test -e "$available" && sudo -n cmp -s "$candidate" "$available" && sudo -n test -L "$enabled"; then
        echo "$(basename "$source") already installed"
        rm -f "$candidate"
        return
    fi

    if sudo -n test -e "$available"; then
        backup="$(mktemp)"
        sudo -n cp "$available" "$backup"
    fi
    sudo -n install -o root -g root -m 644 "$candidate" "$available"
    rm -f "$candidate"
    if ! sudo -n test -L "$enabled"; then
        sudo -n ln -s "$available" "$enabled"
        linked=true
    fi

    if sudo -n nginx -t; then
        sudo -n systemctl reload nginx
        echo "$(basename "$source") installed, nginx reloaded"
        [ -z "$backup" ] || rm -f "$backup"
        return
    fi

    if [ -n "$backup" ]; then
        sudo -n install -o root -g root -m 644 "$backup" "$available"
        rm -f "$backup"
    else
        sudo -n rm -f "$available"
    fi
    if $linked; then
        sudo -n rm -f "$enabled"
    fi
    die "nginx -t failed with $(basename "$source"): the previous site file is back, nginx was not reloaded"
}

main() {
    local dir="$1" host="$2"
    local sites="$dir/app.new/deploy/nginx"

    if ! sudo -n test -e "/etc/letsencrypt/live/$host/fullchain.pem"; then
        install_site "$sites/exlibris.lunabee.ovh.bootstrap.conf" "$host"
        sudo -n certbot certonly --nginx -d "$host" --non-interactive --keep-until-expiring
    fi
    install_site "$sites/exlibris.lunabee.ovh.conf" "$host"
}
STEP
fi

printf '== Building and starting %s\n' "$project"
remote_step "$dir" "$project" <<'STEP'
main() {
    local dir="$1" project="$2"
    rm -rf "$dir/app.previous"
    if [ -d "$dir/app" ]; then
        mv "$dir/app" "$dir/app.previous"
    fi
    mv "$dir/app.new" "$dir/app"
    stack "$dir" "$project" up -d --build --remove-orphans
}
STEP

printf '== Waiting for https://%s/health\n' "$host"
healthy=false
for _ in $(seq 1 36); do
    if curl -fsS --max-time 10 "https://$host/health" >/dev/null 2>&1; then
        healthy=true
        break
    fi
    sleep 5
done

if ! $healthy; then
    printf 'deploy-backend: https://%s/health did not answer within 3 minutes. The backend'\''s last lines:\n' "$host" >&2
    remote_step "$dir" "$project" <<'STEP' >&2 || true
main() {
    stack "$1" "$2" logs --tail 80 backend
}
STEP
    exit 1
fi

remote_step "$dir" "$sha" "$ref" <<'STEP'
main() {
    printf '%s %s %s\n' "$2" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$3" >>"$1/DEPLOYED"
    printf 'Deployed: '
    tail -n 1 "$1/DEPLOYED"
}
STEP

if $setup; then
    cat <<EOF

Setup done. E-mails leave only once Brevo's SMTP login and key are in $dir/.env:
  ssh -t -i $ssh_key $ssh_target 'nano $dir/.env'  # fill SMTP_USER and SMTP_PASSWORD
  scripts/deploy-backend.sh                          # recreates the backend with them
EOF
fi
