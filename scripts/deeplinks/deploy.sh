#!/bin/bash
# Publishes the Ex-libris link domain, link.exlibris.lunabee.ovh, on Lunabee's VPS: the nginx site,
# the two files that tie it to the apps, and the link-preview service (preview/, a Docker Compose
# project in /opt/exlibris-preview on 127.0.0.1:8620). Safe to run again after editing any of them.
#
#   scripts/deeplinks/deploy.sh
#
# The first run asks certbot for the certificate. EXLIBRIS_VPS overrides the SSH target: the IP
# (vps-25914896.vps.ovh.net) is the name its host key is known by.
set -euo pipefail

HOST="link.exlibris.lunabee.ovh"
VPS="${EXLIBRIS_VPS:-debian@37.59.107.30}"
KEY="${EXLIBRIS_VPS_KEY:-$HOME/.ssh/exlibris_vps}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SSH=(ssh -i "$KEY" -o IdentitiesOnly=yes "$VPS")
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

python3 -m json.tool "$HERE/apple-app-site-association" > /dev/null
python3 -m json.tool "$HERE/assetlinks.json" > /dev/null

# The service's sources, without its tests or anything macOS adds to an archive.
COPYFILE_DISABLE=1 tar -C "$HERE" --no-xattrs --no-mac-metadata \
    --exclude __pycache__ --exclude tests -czf "$BUILD/preview.tgz" preview

"${SSH[@]}" "mkdir -p /tmp/deeplinks"
scp -i "$KEY" -o IdentitiesOnly=yes \
    "$HERE/apple-app-site-association" "$HERE/assetlinks.json" "$HERE/$HOST.conf" "$BUILD/preview.tgz" \
    "$VPS:/tmp/deeplinks/"

"${SSH[@]}" bash -s "$HOST" <<'REMOTE'
set -euo pipefail
HOST="$1"
trap 'rm -rf /tmp/deeplinks' EXIT
ROOT="/var/www/$HOST/.well-known"
APP="/opt/exlibris-preview"
SITE="/etc/nginx/sites-available/$HOST"
sudo mkdir -p "$ROOT"
sudo install -m 644 /tmp/deeplinks/apple-app-site-association /tmp/deeplinks/assetlinks.json "$ROOT/"

if ! sudo test -d "/etc/letsencrypt/live/$HOST"; then
    # No certificate yet: serve port 80 alone so certbot can answer its challenge.
    printf 'server {\n    listen 80;\n    listen [::]:80;\n    server_name %s;\n    location / { return 404; }\n}\n' "$HOST" \
        | sudo tee "$SITE" > /dev/null
    sudo ln -sf "$SITE" "/etc/nginx/sites-enabled/zz-$HOST"
    sudo nginx -t && sudo systemctl reload nginx
    sudo certbot certonly --nginx --non-interactive --keep-until-expiring -d "$HOST"
fi

# The service first, so that the site never sends a robot to a port nobody listens on for long.
# Its covers live in the project's `covers` volume, not in $APP, which is replaced whole.
sudo mkdir -p "$APP"
sudo find "$APP" -mindepth 1 -delete
sudo tar --warning=no-unknown-keyword -xzf /tmp/deeplinks/preview.tgz -C "$APP" --strip-components=1
sudo docker compose -p exlibris-preview -f "$APP/docker-compose.yml" up -d --build --remove-orphans

# The site's page cache; nginx gives it to its workers' user when it starts.
sudo mkdir -p /var/cache/nginx/exlibris-preview

# The site file holds global directives (a cache, a zone, maps): on a shared server, one that fails
# `nginx -t` is put back as it was, or taken out when there was none, so that the next reload of
# another project still works.
if sudo test -f "$SITE"; then
    sudo cp "$SITE" "$SITE.previous"
fi
sudo install -m 644 "/tmp/deeplinks/$HOST.conf" "$SITE"
sudo ln -sf "$SITE" "/etc/nginx/sites-enabled/zz-$HOST"
if ! sudo nginx -t; then
    if sudo test -f "$SITE.previous"; then
        sudo mv "$SITE.previous" "$SITE"
        echo "nginx -t failed: $SITE put back as it was, nginx not reloaded." >&2
    else
        sudo rm -f "/etc/nginx/sites-enabled/zz-$HOST" "$SITE"
        echo "nginx -t failed: $SITE taken out, nginx not reloaded." >&2
    fi
    exit 1
fi
sudo systemctl reload nginx
sudo rm -f "$SITE.previous"
REMOTE

# nginx reloads its workers in the background: the old ones may still answer for a moment.
sleep 3

curl -fsS -o /dev/null -w "AASA %{http_code} %{content_type}\n" "https://$HOST/.well-known/apple-app-site-association"
curl -fsS -o /dev/null -w "assetlinks %{http_code} %{content_type}\n" "https://$HOST/.well-known/assetlinks.json"
curl -sS -o /dev/null -w "redirect %{http_code} -> %{redirect_url}\n" "https://$HOST/entity/isbn:9782070360024"

# What a link-preview robot reads, one page per kind of link: two fixed entities, a missing list
# and a uri the apps refuse (both « Ex-libris »), then public objects inventaire.io shows at the
# time, so that no reader's name or id is kept here. A kind it shows none of is « skipped ».
ROBOT="facebookexternalhit/1.1"
meta() {
    python3 -c 'import html, re, sys
found = re.search(r"property=\"og:%s\" content=\"([^\"]*)\"" % sys.argv[1], sys.stdin.read())
print(html.unescape(found[1]) if found else "")' "$1"
}
preview() {
    local page
    page="$(curl -sS -A "$ROBOT" "https://$HOST$2")"
    echo "robot $1 $2: $(meta title <<< "$page") | $(meta description <<< "$page") | $(meta image <<< "$page")"
}
for path in \
    /entity/isbn:9782070360024 \
    /entity/wd:Q34670 \
    /lists/00000000000000000000000000000000 \
    "/entity/wd:Q1%7Cwd:Q2"; do
    preview fixed "$path"
done
while IFS=$'\t' read -r kind path; do
    if [ -n "$path" ]; then
        preview "$kind" "$path"
    else
        echo "robot $kind: skipped"
    fi
done < <(python3 "$HERE/find_public_objects.py")

# Both images are 1200 × 630 JPEGs: expect image/jpeg, well under WhatsApp's size limit.
book_image="$(curl -sS -A "$ROBOT" "https://$HOST/entity/isbn:9782070360024" | meta image)"
for image in "$book_image" "https://$HOST/og/ex-libris.jpg"; do
    curl -fsS -o /dev/null -w "image %{http_code} %{content_type} %{size_download} bytes <- $image\n" "$image"
done
