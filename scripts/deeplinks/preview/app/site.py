"""What the service answers for a path: a link's page, or one of the images its pages name."""

import logging
from dataclasses import dataclass
from pathlib import Path

from . import tags
from .cover import Covers, CoverUnavailable
from .inventaire import Inventaire, Unreachable
from .page import PageURLs, render
from .paths import Link, parse
from .previews import read_preview

PAGE_MAX_AGE: int = 60 * 60
RETRY_MAX_AGE: int = 60
ASSET_MAX_AGE: int = 24 * 60 * 60
COVER_MAX_AGE: int = 365 * 24 * 60 * 60

STATIC_IMAGE: str = "ex-libris.jpg"
_ASSETS: tuple[str, ...] = (STATIC_IMAGE, "favicon.png", "apple-touch-icon.png")
_CONTENT_TYPES: dict[str, str] = {".jpg": "image/jpeg", ".png": "image/png"}
_COVER_PREFIX: str = "/og/cover/"
_ASSET_PREFIX: str = "/og/"

_logger: logging.Logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Response:
    """What the HTTP handler sends: a status, a body and how long it may be kept, in seconds."""

    status: int
    content_type: str
    body: bytes
    max_age: int


class Site:
    """The pages of `base_url`'s links, read from inventaire.io, and their images."""

    def __init__(self, base_url: str, inventaire: Inventaire, covers: Covers, assets: Path) -> None:
        self._base_url: str = base_url
        self._inventaire: Inventaire = inventaire
        self._covers: Covers = covers
        self._assets: dict[str, bytes] = {name: (assets / name).read_bytes() for name in _ASSETS}

    def respond(self, raw_path: str) -> Response:
        """The answer to a GET of `raw_path`, as the client sent it.

        Args:
            raw_path: The request's path and query, percent-encoded.
        """
        path: str = raw_path.partition("?")[0]
        if path.startswith(_COVER_PREFIX):
            return self._cover(path.removeprefix(_COVER_PREFIX).removesuffix(".jpg"))
        if path.startswith(_ASSET_PREFIX):
            return self._asset(path.removeprefix(_ASSET_PREFIX))
        return self._page(raw_path)

    def _page(self, raw_path: str) -> Response:
        link: Link | None = parse(raw_path)
        preview: tags.Preview = tags.GENERIC
        max_age: int = PAGE_MAX_AGE
        if link is not None:
            try:
                preview = read_preview(link, self._inventaire) or tags.GENERIC
            except Unreachable as error:
                _logger.warning("%s: inventaire.io unreachable (%s)", raw_path, error)
                max_age = RETRY_MAX_AGE
        image: str = f"/og/{STATIC_IMAGE}"
        if preview.cover_url:
            try:
                key: str | None = self._covers.compose(preview.cover_url)
                if key is not None:
                    image = f"{_COVER_PREFIX}{key}.jpg"
            except CoverUnavailable as error:
                _logger.warning("%s: no cover (%s)", raw_path, error.__cause__ or error)
                max_age = RETRY_MAX_AGE
        urls: PageURLs = PageURLs(
            page=f"{self._base_url}{link.path if link else raw_path}",
            image=f"{self._base_url}{image}",
            favicon=f"{self._base_url}/og/favicon.png",
            apple_touch_icon=f"{self._base_url}/og/apple-touch-icon.png",
            inventaire=f"{self._inventaire.base_url}{raw_path}"
        )
        return Response(200, "text/html; charset=utf-8", render(preview, urls).encode(), max_age)

    def _cover(self, key: str) -> Response:
        path: Path | None = self._covers.file(key)
        if path is None:
            return _not_found()
        return Response(200, "image/jpeg", path.read_bytes(), COVER_MAX_AGE)

    def _asset(self, name: str) -> Response:
        body: bytes | None = self._assets.get(name)
        if body is None:
            return _not_found()
        return Response(200, _CONTENT_TYPES[Path(name).suffix], body, ASSET_MAX_AGE)


def _not_found() -> Response:
    return Response(404, "text/plain; charset=utf-8", b"Not found\n", RETRY_MAX_AGE)
