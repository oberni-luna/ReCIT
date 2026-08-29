#!/usr/bin/env python3
"""Turn the scenario's report.json into a readable compte-rendu.

Writes `report.html` (screenshots, one row per step) and `report.md` (the same table,
for reading in a terminal or pasting into an issue) next to the JSON, and prints a
summary to stdout.

Usage: e2e_report.py <report-directory>
"""

import base64
import html
import json
import os
import shutil
import subprocess
import sys
import tempfile

STATUS_STYLE = {
    "OK": ("ok", "OK"),
    "KO": ("ko", "KO"),
    "SKIP": ("skip", "NON JOUÉ"),
}

CSS = """
:root {
  --bg: #ffffff; --fg: #1c1b1a; --muted: #6b6863; --line: #e6e2dc;
  --ok: #1f7a4d; --ok-bg: #eaf6ef; --ko: #b3261e; --ko-bg: #fceceb;
  --skip: #8a6d1f; --skip-bg: #fdf4e0;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #16150f; --fg: #f2efe9; --muted: #a8a29a; --line: #33302a;
    --ok: #6fd39b; --ok-bg: #12301f; --ko: #f2857c; --ko-bg: #331714;
    --skip: #e3c46a; --skip-bg: #2e2712;
  }
}
* { box-sizing: border-box; }
body { margin: 0; padding: 32px 20px 64px; background: var(--bg); color: var(--fg);
  font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; }
.wrap { max-width: 1080px; margin: 0 auto; }
h1 { font-size: 26px; margin: 0 0 4px; }
.meta { color: var(--muted); font-size: 14px; margin-bottom: 24px; }
.meta code { font-size: 13px; }
.totals { display: flex; gap: 10px; flex-wrap: wrap; margin: 0 0 28px; }
.pill { padding: 6px 12px; border-radius: 999px; font-weight: 600; font-size: 13px; }
.pill.ok { background: var(--ok-bg); color: var(--ok); }
.pill.ko { background: var(--ko-bg); color: var(--ko); }
.pill.skip { background: var(--skip-bg); color: var(--skip); }
.step { display: grid; grid-template-columns: 180px 1fr; gap: 20px;
  padding: 20px 0; border-top: 1px solid var(--line); align-items: start; }
.step:last-child { border-bottom: 1px solid var(--line); }
.shot img { width: 100%; border-radius: 10px; border: 1px solid var(--line); display: block; }
.shot .none { color: var(--muted); font-size: 13px; font-style: italic; }
.title { font-weight: 600; font-size: 16px; margin: 0 0 6px; }
.num { color: var(--muted); font-weight: 400; }
.detail { margin: 0 0 8px; }
.why { background: var(--ko-bg); color: var(--ko); padding: 10px 12px;
  border-radius: 8px; margin: 8px 0 0; white-space: pre-wrap; }
.dur { color: var(--muted); font-size: 13px; }
@media (max-width: 640px) { .step { grid-template-columns: 1fr; } .shot img { max-width: 260px; } }
"""


THUMBNAIL_WIDTH = 360


def thumbnail_data_uri(path):
    """A small JPEG copy of a screenshot, as a data: URI.

    Embedding the thumbnails is what makes report.html a single file worth sending to
    somebody: the full-size PNGs stay beside it for the click-through, but the page reads
    on its own even when it travels alone. `sips` ships with macOS; if it is not there, or
    it fails, the caller falls back to referencing the PNG.
    """
    if not shutil.which("sips"):
        return None

    with tempfile.TemporaryDirectory() as workspace:
        out = os.path.join(workspace, "thumb.jpg")
        try:
            subprocess.run(
                ["sips", "-Z", str(THUMBNAIL_WIDTH), "-s", "format", "jpeg",
                 path, "--out", out],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            with open(out, "rb") as handle:
                encoded = base64.b64encode(handle.read()).decode("ascii")
        except (subprocess.CalledProcessError, OSError):
            return None

    return "data:image/jpeg;base64," + encoded


def render_html(data, directory):
    steps = data.get("steps", [])
    parts = [
        "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\">",
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
        "<title>%s</title>" % html.escape(data.get("scenario", "Compte-rendu E2E")),
        "<style>%s</style></head><body><div class=\"wrap\">" % CSS,
        "<h1>%s</h1>" % html.escape(data.get("scenario", "Compte-rendu E2E")),
        "<p class=\"meta\">Compte&nbsp;: <code>%s</code> &middot; appareil&nbsp;: %s<br>"
        "Début&nbsp;: %s &middot; fin&nbsp;: %s</p>"
        % (
            html.escape(data.get("account", "?")),
            html.escape(data.get("device", "?")),
            html.escape(data.get("startedAt", "?")),
            html.escape(data.get("finishedAt") or "interrompu"),
        ),
        "<div class=\"totals\">"
        "<span class=\"pill ok\">%d OK</span>"
        "<span class=\"pill ko\">%d KO</span>"
        "<span class=\"pill skip\">%d non joués</span></div>"
        % (data.get("okCount", 0), data.get("koCount", 0), data.get("skippedCount", 0)),
    ]

    for step in steps:
        css_class, label = STATUS_STYLE.get(step.get("status", "KO"), ("ko", "KO"))
        shot = step.get("screenshot")
        shot_path = os.path.join(directory, shot) if shot else None
        if shot_path and os.path.exists(shot_path):
            source = thumbnail_data_uri(shot_path) or shot
            shot_html = '<a href="%s"><img src="%s" alt=""></a>' % (shot, source)
        else:
            shot_html = '<p class="none">pas de capture</p>'

        why = ""
        if step.get("message"):
            why = '<p class="why">%s</p>' % html.escape(step["message"])

        parts.append(
            '<div class="step"><div class="shot">%s</div><div>'
            '<p class="title"><span class="num">%02d.</span> %s '
            '<span class="pill %s">%s</span></p>'
            '<p class="detail">%s</p>'
            '<p class="dur">%.1f s</p>%s</div></div>'
            % (
                shot_html,
                step.get("index", 0),
                html.escape(step.get("title", "")),
                css_class,
                label,
                html.escape(step.get("detail") or "—"),
                step.get("durationSeconds", 0.0),
                why,
            )
        )

    parts.append("</div></body></html>")
    return "".join(parts)


def render_markdown(data):
    lines = [
        "# %s" % data.get("scenario", "Compte-rendu E2E"),
        "",
        "- Compte : `%s`" % data.get("account", "?"),
        "- Appareil : %s" % data.get("device", "?"),
        "- Début : %s" % data.get("startedAt", "?"),
        "- Fin : %s" % (data.get("finishedAt") or "interrompu"),
        "- Résultat : **%d OK / %d KO / %d non joués**"
        % (data.get("okCount", 0), data.get("koCount", 0), data.get("skippedCount", 0)),
        "",
        "| # | Étape | Détail | État | Durée |",
        "| --- | --- | --- | --- | --- |",
    ]
    for step in data.get("steps", []):
        detail = (step.get("detail") or "—").replace("|", "\\|")
        lines.append(
            "| %02d | %s | %s | %s | %.1f s |"
            % (
                step.get("index", 0),
                step.get("title", "").replace("|", "\\|"),
                detail,
                step.get("status", "?"),
                step.get("durationSeconds", 0.0),
            )
        )

    failures = [s for s in data.get("steps", []) if s.get("status") == "KO"]
    if failures:
        lines += ["", "## Échecs", ""]
        for step in failures:
            lines.append("- **%02d. %s** — %s" % (step.get("index", 0), step.get("title", ""), step.get("message", "")))

    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2

    directory = sys.argv[1]
    json_path = os.path.join(directory, "report.json")
    if not os.path.exists(json_path):
        print("Aucun report.json dans %s" % directory, file=sys.stderr)
        return 1

    with open(json_path, encoding="utf-8") as handle:
        data = json.load(handle)

    with open(os.path.join(directory, "report.html"), "w", encoding="utf-8") as handle:
        handle.write(render_html(data, directory))
    with open(os.path.join(directory, "report.md"), "w", encoding="utf-8") as handle:
        handle.write(render_markdown(data))

    for step in data.get("steps", []):
        marker = {"OK": "  OK  ", "KO": "  KO  ", "SKIP": " SKIP "}.get(step.get("status"), "  ??  ")
        print("[%s] %02d. %s — %s" % (marker, step.get("index", 0), step.get("title", ""), step.get("detail") or ""))
        if step.get("message"):
            print("          ↳ %s" % step["message"])

    print()
    print(
        "Résultat : %d OK / %d KO / %d non joués"
        % (data.get("okCount", 0), data.get("koCount", 0), data.get("skippedCount", 0))
    )
    return 1 if data.get("koCount", 0) else 0


if __name__ == "__main__":
    sys.exit(main())
