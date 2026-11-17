#!/bin/bash
# Publishes the Ex-libris link domain, link.exlibris.lunabee.ovh, on Lunabee's VPS: the nginx site
# and the two files that tie it to the apps. Safe to run again after editing any of them.
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

python3 -m json.tool "$HERE/apple-app-site-association" > /dev/null
python3 -m json.tool "$HERE/assetlinks.json" > /dev/null

"${SSH[@]}" "mkdir -p /tmp/deeplinks"
scp -i "$KEY" -o IdentitiesOnly=yes \
    "$HERE/apple-app-site-association" "$HERE/assetlinks.json" "$HERE/$HOST.conf" \
    "$VPS:/tmp/deeplinks/"

"${SSH[@]}" bash -s "$HOST" <<'REMOTE'
set -euo pipefail
HOST="$1"
ROOT="/var/www/$HOST/.well-known"
sudo mkdir -p "$ROOT"
sudo install -m 644 /tmp/deeplinks/apple-app-site-association /tmp/deeplinks/assetlinks.json "$ROOT/"

if ! sudo test -d "/etc/letsencrypt/live/$HOST"; then
    # No certificate yet: serve port 80 alone so certbot can answer its challenge.
    printf 'server {\n    listen 80;\n    listen [::]:80;\n    server_name %s;\n    location / { return 404; }\n}\n' "$HOST" \
        | sudo tee "/etc/nginx/sites-available/$HOST" > /dev/null
    sudo ln -sf "/etc/nginx/sites-available/$HOST" "/etc/nginx/sites-enabled/zz-$HOST"
    sudo nginx -t && sudo systemctl reload nginx
    sudo certbot certonly --nginx --non-interactive --keep-until-expiring -d "$HOST"
fi

sudo install -m 644 "/tmp/deeplinks/$HOST.conf" "/etc/nginx/sites-available/$HOST"
sudo ln -sf "/etc/nginx/sites-available/$HOST" "/etc/nginx/sites-enabled/zz-$HOST"
sudo nginx -t && sudo systemctl reload nginx
rm -rf /tmp/deeplinks
REMOTE

# nginx reloads its workers in the background: the old ones may still answer for a moment.
sleep 3

curl -fsS -o /dev/null -w "AASA %{http_code} %{content_type}\n" "https://$HOST/.well-known/apple-app-site-association"
curl -fsS -o /dev/null -w "assetlinks %{http_code} %{content_type}\n" "https://$HOST/.well-known/assetlinks.json"
curl -sS -o /dev/null -w "redirect %{http_code} -> %{redirect_url}\n" "https://$HOST/entity/isbn:9782070360024"
