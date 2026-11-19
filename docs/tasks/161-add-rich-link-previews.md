---
issue: 161
status: to-close
wiki: [[features/0092-entity-deep-links]], [[features/0093-network-deep-links]], [[features/0094-list-deep-links]], [[features/0095-inventory-deep-links]], [[design-system/figma-library]]
note: Mock-ups on Figma page Social Preview (file S7IvC6GvlcUFe5IgbtvQq6, frame 1110:2, rules block 1111:143). Grilled 2026-11-18. Recit_Backend/ (Kotlin, #62) is not on main and not online, so it is not used here.
created: 2026-11-18
---

## Context / Decisions

> Rich link previews for link.exlibris.lunabee.ovh. Today `scripts/deeplinks/link.exlibris.lunabee.ovh.conf` answers every path with a 302 to inventaire.io, and inventaire.io serves no per-page Open Graph tags (only its generic `<title>`, no `og:image`), so iMessage, WhatsApp and Slack show a generic card.

A link to a book shared from Ex-libris shows its cover in iMessage, WhatsApp, Slack and the rest. Any other link shows its name and what it is, under one Ex-libris image.

1. **Where.** A small service of its own in `scripts/deeplinks/preview/`: Python 3 + Pillow, a Docker Compose project on the shared VPS bound to `127.0.0.1:86x0`, as Lunabee's other projects there (pick a free port; `8630` is the backend's). Not a route in `Recit_Backend/`.
2. **Who gets it.** Only link-preview robots. nginx sends a request to the service when `$http_user_agent` matches a `map`: `facebookexternalhit` (also iMessage), `WhatsApp`, `Slackbot`, `Discordbot`, `TelegramBot`, `Twitterbot`, `LinkedInBot`, `Mastodon`, `bot|crawler|spider`. Everyone else keeps today's `302` to the same path on inventaire.io. Service down → the robot gets that `302` too (nginx fallback), never an error page.
3. **Paths.** The ones the apps open: `/entity/<uri>`, `/items/<id>`, `/lists/<id>`, `/lists/<id>/element/<elementId>`, `/shelves/<id>`, `/users/<username>`, `/groups/<slug>`. Same whole-match rules as the apps (`DeepLink`): a path that doesn't parse → the static page, and nothing from the URL reaches a query string unchecked (0092's `%7C` / `%26` pitfall).
4. **Reads.** inventaire.io's public API only, never a session: `GET /api/entities/by-uris`, `/items/by-ids`, `/lists/by-ids`, `/shelves/by-ids`, `/users/by-usernames`, `/groups/by-slug`. Path style, never the deprecated `?action=`. A private or missing object answers like an unknown one.
5. **Two images, both JPEG 1200 × 630 (quality 85, progressive), on the night green background.** JPEG rather than PNG: ~50 KB instead of ~600 KB, under WhatsApp's image size limit (changed while coding, 2026-11-18).
   - **Book** (`/entity` of a work or an edition, `/items`, `/lists/…/element/…`): the cover alone, 340 × 510, corners of 8, centred on the background, composed by the service. No cover → the static image.
   - **Everything else** (author, list, étagère, reader, group, private, missing, API error): one static file, the Ex-libris icon and name, served as is.
   - The background and the static image are exported from Figma (`Social Preview / Background`, `OG · Ex-libris`) into the repo. The voile's gradient values are hard-coded in Figma: export, don't redraw.
6. **Tags.** Each page carries `og:title`, `og:description`, `og:image` (+ `og:image:width` / `height`), `og:url`, `og:site_name` = `Ex-libris`, `twitter:card` = `summary_large_image`, a favicon and an `apple-touch-icon`. The name of the object is never in the image.
   - Book: « Lucioles » / « Collectif · La Volte, sur Ex-libris »
   - Book from an inventory: « Riche, pourquoi pas toi ? » / « Marion Montaigne · chez Léa, sur Ex-libris » (glossary: a copy is a « livre », never « exemplaire »)
   - Book from a list: « Lucioles » / « Dans la liste « Pour changer le monde » de Léa, sur Ex-libris »
   - Author: « Ken Loach sur Ex-libris » / their description
   - List: « Pour changer le monde » / « Une liste de Léa sur Ex-libris · 8 œuvres »
   - Étagère: « À lire cet été » / « Une étagère de Rémi sur Ex-libris · 14 livres »
   - Reader: « Léa sur Ex-libris » / their bio, else « 540 livres · 4 listes »
   - Group: « Polar & noir sur Ex-libris » / its description, else « 23 membres »
   - Private, missing, error: « Ex-libris » / « Vos livres, et ceux qui circulent », nothing about the object
   - Counts agree in number (« 1 œuvre », « 8 œuvres »). Narrow no-break space before `? ! : ;`.
7. **Language.** French sentences. inventaire.io labels in `fr`, else `en`, else the original language. No `Accept-Language`.
8. **Cache.** nginx `proxy_cache` keeps each page 1 h. A book image is written once to disk under its cover hash (`/og/cover/<hash>.png`) and never expires.
9. **Deploy.** `scripts/deeplinks/deploy.sh` grows the container, the `map`, the cache and the fallback; `nginx -t` before every reload, as today. The VPS is shared: touch nothing of the other projects. Run it, then check with `curl`.

### Out of scope

- Per-object images for anything but books (avatars, list piles, étagères): dropped after the first mock-ups.
- English sentences, `Accept-Language`.
- Changes to the iOS or Android apps.

## Acceptance criteria

- `curl -A "facebookexternalhit/1.1" https://link.exlibris.lunabee.ovh/entity/isbn:9782070360024` → HTML with `og:title` « L'Étranger », `og:site_name` « Ex-libris », and an `og:image` that downloads as a 1200 × 630 JPEG showing the cover on the green background.
- The same `curl` on a public list, a public étagère, a reader and a group → the `og:title` / `og:description` of decision 6, and the static Ex-libris image.
- A `/items/<id>` link → `og:description` « <author> · chez <owner>, sur Ex-libris » and the cover image.
- A `/lists/<id>/element/<elementId>` link → the book's title, « Dans la liste « … » de …, sur Ex-libris », and the cover image.
- A private list, a missing id, and `/entity/wd:Q1%7Cwd:Q2` → `og:title` « Ex-libris », the static image, no name.
- `curl` without a robot user agent on any of these → `302` to the same path on `https://inventaire.io`, as today.
- Service stopped → a robot gets the `302`, not a `502`.
- A second robot request for the same link within the hour → no new call to inventaire.io (service log).
- `.well-known/apple-app-site-association` and `assetlinks.json` still answer as JSON, without a redirect.
- Unit tests for path parsing and tag building (fixture JSON from inventaire.io) pass locally.
- Olivier shares a book link and a list link in iMessage and Slack: the book shows its cover, the list its name and the Ex-libris image.

## Implementation

Round 1, 2026-11-18. Coded in a separate worktree: another session was working in the main checkout.

- **Service** `scripts/deeplinks/preview/`: Python 3.13 + Pillow 12.3, stdlib `ThreadingHTTPServer`, Docker Compose project `exlibris-preview` on `127.0.0.1:8620`, covers in the named volume `covers`.
  - `app/paths.py` whole-match parse, a port of `DeepLink.swift` · `inventaire.py` API client, no cookie, 3 s timeout · `entities.py` labels fr → en → original · `previews.py` the reads per kind · `tags.py` texts per kind · `cover.py` composition and disk cache · `page.py` escaped HTML · `site.py` routing and `Cache-Control` · `server.py` entry.
  - Book image: `assets/background.png` + cover 340 × 510 at (430, 60), radius 8, JPEG quality 85 progressive, `/og/cover/<key>.jpg`, ~50 KB. Static image `assets/ex-libris.jpg`, 25 KB. Both exported from Figma.
  - Pages `max-age=3600`; generic fallback after an API timeout, or a page whose cover failed, only 60 s.
  - Authors from P50, P58, P110, P6338 through one `entities/by-uris` with `relatives`. An edition takes its work's label when they match ignoring case (« L'Étranger »).
  - Any 4xx from inventaire.io, or a list, étagère or item not `public`, → the generic page.
- **nginx** `link.exlibris.lunabee.ovh.conf`: global `proxy_cache_path` (`exlibris_preview`), `limit_req_zone` (`exlibris_preview_req`, 10 r/s per IP, burst 20) and the maps `$exlibris_preview_robot`, `$exlibris_preview_path` (path as sent, without query); robots on the 7 paths → the service through a `418` named location, cached 1 h under the raw path; `/og/` for everyone; a 429/500/502/503/504 → the `302`.
- **Images read** only over https from `inventaire.io`, `commons`, `upload`, `thumb.wikimedia.org`, every redirect hop re-checked; past 40 M pixels refused; at most 10 000 covers kept, evicted by last use.
- **deploy.sh**: ships `preview/` (no tests) to `/opt/exlibris-preview`, `docker compose up -d --build`, then the site file; a failing `nginx -t` puts the previous file back and exits 1. Ends with a robot `curl` per kind of link, on public objects found at deploy time, and both images.
- **Tests**: 68 `unittest` cases (paths, tags, previews on fixtures recorded from the live API then anonymized, page, cover, site, allowed image hosts), run in a `python:3.13-slim` container.
- **Deployed** 2026-11-18 on the VPS. `home.lunabee.ovh` still 200 afterwards.

## Review

Round `validation`, 2026-11-18, one wa-verifier, four lenses, autofix 3 rounds. Final: style ✓ · elegance ✓ · structure ✓ · correctness ✓, nothing open.

- Round 1, 15 findings, all fixed:
  - major [correctness] cache key kept the query and nothing limited robots → any `?x=` drove unlimited inventaire.io reads from the VPS IP. Fixed: key without query, `limit_req` 10 r/s burst 20, 429 → `302`.
  - minor [correctness] SSRF on cover URLs (any https host, redirects unchecked) → host allowlist, https only, every hop re-checked.
  - minor [correctness] decompression bomb → 40 M pixels cap before decode, `draft`.
  - minor [correctness] covers volume unbounded → 10 000 covers cap.
  - minor [correctness] `_is_public` no-op when `visibility` is absent → documented as second guard, tests for friends-only item, étagère, list.
  - minor [correctness] failed `nginx -t` without previous file left the site enabled → removed.
  - minor [structure] discovery Python inside a bash heredoc → `find_public_objects.py`.
  - minor/nit [structure, style, elegance] two `Entity` names, missing docstrings, `compose` twice, unannotated test locals, `list_count=0` sentinel, `y` elision, tmp files left on rollback, test count.
- Round 2, 8 findings, all fixed: cache key on decoded `$uri` let `%2F` / `/../` poison a real link → key on the raw path; one extra read for readers with a bio; eviction by write time → by last use; `Refused` retried every minute → permanent miss; `thumb.wikimedia.org` kept with its observed redirect chain; docstring; test annotations; docs.
- Round 3, 1 nit (wiki wording), fixed by hand.
- Autofix changed code after the first deploy: redeployed before landing.

## Verification

On the live server, from `deploy.sh` and `curl`, 2026-11-18:

- ✅ `/entity/isbn:9782070360024` → « L'Étranger » | « Albert Camus · Éditions Gallimard, sur Ex-libris » | `/og/cover/33f0…d9bd.jpg`, 200 `image/jpeg`, 49 790 bytes, 1200 × 630, cover centred on the green background (looked at).
- ✅ `/entity/wd:Q34670` → « Albert Camus sur Ex-libris » | « écrivain, philosophe et journaliste français » | static image.
- ✅ A public `/items/<id>` → its title | « <authors> · chez <owner>, sur Ex-libris » | cover.
- ✅ A public `/lists/<id>` → its name | « Une liste de <owner> sur Ex-libris · 20 œuvres » | static.
- ✅ `/lists/<id>/element/<id>` → « L'Étranger » | « Dans la liste « <name> » de <owner>, sur Ex-libris » | cover.
- ✅ A public `/shelves/<id>` → its name | « Une étagère de <owner> sur Ex-libris · 8 livres » | static.
- ✅ A public `/users/<username>` → « <username> sur Ex-libris » | « 125 livres · 2 listes », or their bio.
- ✅ A public `/groups/<slug>` → « <name> sur Ex-libris » | « 1 membre ».
- ✅ Missing list and `/entity/wd:Q1%7Cwd:Q2` → « Ex-libris » | « Vos livres, et ceux qui circulent » | static.
- ✅ Browser user agent → `302` to the same path on inventaire.io. AASA and assetlinks 200 `application/json`.
- ✅ Locally (nginx + service in Docker): service stopped → robots get the `302`; 3 robot requests → 1 call to inventaire.io.
- ⏳ Private list: unit tests only, none reachable anonymously.
- ⏳ iMessage and Slack shares: Olivier.

## Feedback
