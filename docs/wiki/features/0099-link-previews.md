# Link previews: a book's cover, everything else its name

Shipped on 2026-11-18, server side only (issue #161, PR #165). A link on `link.exlibris.lunabee.ovh` pasted in
iMessage, WhatsApp, Slack, Discord, Telegram, Mastodon or LinkedIn shows a preview of its own instead of
inventaire.io's generic card: the cover for a book, the name and what it is for anything else. Checked with `curl` as
the robots; real shares in the apps left to Olivier. Mock-ups: Figma page `Social Preview` (`1110:2`, see
[figma-library](../design-system/figma-library.md)).

## What it does

- **Who sees it.** Only link-preview robots, picked by user agent (`facebookexternalhit`, which iMessage also sends,
  `WhatsApp`, `Slackbot`, `Discordbot`, `TelegramBot`, `Twitterbot`, `LinkedInBot`, `Mastodon`, `bot|crawler|spider`).
  A person still gets the `302` to the same page on inventaire.io, and the app still opens the link when installed.
- **Which links.** The seven the apps open: `/entity/<uri>`, `/items/<id>`, `/lists/<id>`,
  `/lists/<id>/element/<id>`, `/shelves/<id>`, `/users/<username>`, `/groups/<slug>`, whole-matched on the apps' rules
  (`DeepLink`) before any request.
- **Two images, both JPEG 1200 × 630 on the night green background.**
  - A book (`/entity` of a work or an edition, `/items`, a list's element): its cover, 340 × 510, centred. About 50 KB.
  - Everything else: one static image, the Ex-libris icon and name. 25 KB.
- **The words carry the name, never the image.** `og:title` and `og:description`, in French:
  - book: « L'Étranger » / « Albert Camus · Éditions Gallimard, sur Ex-libris »
  - a reader's book: « <title> » / « <authors> · chez Léa, sur Ex-libris »
  - a list's book: « <title> » / « Dans la liste « <name> » de Léa, sur Ex-libris »
  - author: « Albert Camus sur Ex-libris » / their description
  - list: « <name> » / « Une liste de Léa sur Ex-libris · 8 œuvres »
  - étagère: « <name> » / « Une étagère d'Émile sur Ex-libris · 14 livres »
  - reader: « Léa sur Ex-libris » / their bio, else « 125 livres · 2 listes »
  - group: « <name> sur Ex-libris » / its description, else « 23 membres »
  - private, missing, malformed, or inventaire.io down: « Ex-libris » / « Vos livres, et ceux qui circulent », nothing
    about the object.
- **Brand.** `og:site_name` « Ex-libris », a favicon and an `apple-touch-icon`: Slack, Discord, Telegram and Facebook
  print it above the preview. iMessage and WhatsApp only show the domain.

## Technical surface

- **Service** — `scripts/deeplinks/preview/`, Python 3.13 + Pillow, stdlib `ThreadingHTTPServer`, no framework. A
  Docker Compose project `exlibris-preview` in `/opt/exlibris-preview` on the shared VPS, on `127.0.0.1:8620`; covers in
  its `covers` volume.
  - `app/paths.py` parses, `inventaire.py` reads the public API (no cookie, 3 s timeout, images capped at 5 s and
    8 MB, https only from `inventaire.io`, `commons`, `upload` and `thumb.wikimedia.org`, every redirect hop
    re-checked), `entities.py` picks labels (`fr`, else `en`, else the original), `previews.py` does the reads per kind,
    `tags.py` writes the texts, `cover.py` composes and caches, `page.py` writes escaped HTML, `site.py` routes.
  - Reads: `entities/by-uris` (with `relatives`, edition → work → authors from P50, P58, P110, P6338),
    `items/by-ids`, `lists/by-ids`, `lists/by-creators`, `shelves/by-ids`, `users/by-usernames`, `users/by-ids`,
    `groups/by-slug`. Any 4xx is treated as missing. The anonymous read is the gate: inventaire.io only answers public objects
    without a session. A `visibility` without `public`, when the answer carries one, is a second guard.
  - Book image: `assets/background.png` (exported from Figma) + the cover from `/img/entities/<W>x<H>/<hash>`, JPEG
    quality 85, progressive, written once as `/og/cover/<key>.jpg` and served `max-age` one year. Images past
    40 M pixels are refused before decoding. At most 10 000 covers (about 0.5 GB) are kept; past that the least
    recently used go, and are made again when a page names them.
- **nginx** — `scripts/deeplinks/link.exlibris.lunabee.ovh.conf`. It sits in the server's `http` block beside other
  projects, so its global names carry a prefix: `proxy_cache_path … keys_zone=exlibris_preview`,
  `map $http_user_agent $exlibris_preview_robot`. A robot on the seven paths goes to the service through a `418`
  named location, cached 1 h (60 s for a fallback page) under the path as sent, without its query
  (`$exlibris_preview_path`): the key is what the service reads, so another spelling can't replace a real link's page,
  and a query string never makes a new page or reaches the service; 10 requests a second per IP, burst 20 (`limit_req_zone … exlibris_preview_req`), past which a
  robot gets the `302`; `/og/` is proxied for everyone; a `429`/`500`/`502`/`503`/`504` falls back to the `302`. The AASA and `assetlinks.json` locations are unchanged.
- **Deploy** — `scripts/deeplinks/deploy.sh` ships `preview/` (without its tests), runs `docker compose up -d --build`,
  then installs the site file. A failing `nginx -t` puts the previous file back and exits: on a shared server, a
  broken global directive would block every other project's reload. It ends with one robot request per kind of link,
  on public objects `find_public_objects.py` finds at deploy time, and both images.
- **Tests** — `python -m unittest` in a `python:3.13-slim` container with `preview/` mounted (the image ships
  without them), 68 cases: parsing, texts, reads on fixtures, page, cover, routing, allowed image hosts.

## Pitfalls

- **The repository is public.** The fixtures are inventaire.io's answers with every reader, list, étagère and group
  replaced by invented ones; only book data was kept. Record new ones the same way, and keep `deploy.sh` free of other
  readers' names.
- **WhatsApp ignores heavy images.** A PNG of the background alone weighs 565 KB; the JPEGs stay near 50 KB.
- **The page cache lives in nginx, not the service.** A renamed list shows its old name for up to an hour. Empty
  `/var/cache/nginx/exlibris-preview` on the VPS to force it.
- **A robot outside the `map` gets inventaire.io's generic card.** Add its user agent to the `map` and redeploy.
