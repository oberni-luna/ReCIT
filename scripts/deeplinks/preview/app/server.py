"""The HTTP entry of the link-preview service, behind nginx: `python -m app.server`.

Configured by the environment: `PREVIEW_PORT` (8620), `PREVIEW_BASE_URL`
(https://link.exlibris.lunabee.ovh), `PREVIEW_CACHE_DIR` (/var/cache/exlibris-preview).
"""

import logging
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from .cover import Covers
from .inventaire import Inventaire
from .site import Response, Site

_ASSETS: Path = Path(__file__).resolve().parent.parent / "assets"

_logger: logging.Logger = logging.getLogger(__name__)


class PreviewServer(ThreadingHTTPServer):
    """One thread per request, all on the same `Site`."""

    daemon_threads: bool = True

    def __init__(self, port: int, site: Site) -> None:
        super().__init__(("0.0.0.0", port), _Handler)
        self.site: Site = site


class _Handler(BaseHTTPRequestHandler):
    server: PreviewServer
    server_version: str = "exlibris-preview"

    def do_GET(self) -> None:
        self._answer(with_body=True)

    def do_HEAD(self) -> None:
        self._answer(with_body=False)

    def log_message(self, format: str, *args: object) -> None:
        _logger.info("%s %s", self.address_string(), format % args)

    def _answer(self, with_body: bool) -> None:
        try:
            response: Response = self.server.site.respond(self.path)
        except Exception:
            _logger.exception("%s failed", self.path)
            response = Response(500, "text/plain; charset=utf-8", b"Internal error\n", 0)
        self.send_response(response.status)
        self.send_header("Content-Type", response.content_type)
        self.send_header("Content-Length", str(len(response.body)))
        self.send_header("Cache-Control", f"public, max-age={response.max_age}")
        self.end_headers()
        if with_body:
            self.wfile.write(response.body)


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    inventaire: Inventaire = Inventaire()
    covers: Covers = Covers(
        directory=Path(os.environ.get("PREVIEW_CACHE_DIR", "/var/cache/exlibris-preview")),
        background=_ASSETS / "background.png",
        inventaire=inventaire
    )
    site: Site = Site(
        base_url=os.environ.get("PREVIEW_BASE_URL", "https://link.exlibris.lunabee.ovh"),
        inventaire=inventaire,
        covers=covers,
        assets=_ASSETS
    )
    port: int = int(os.environ.get("PREVIEW_PORT", "8620"))
    _logger.info("listening on %d", port)
    PreviewServer(port, site).serve_forever()


if __name__ == "__main__":
    main()
