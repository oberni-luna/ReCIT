"""inventaire.io's public API, read without a session: what an anonymous visitor may see."""

import json
import logging
from http.client import HTTPException
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import SplitResult, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, OpenerDirector, Request, build_opener

USER_AGENT: str = "Ex-libris link previews (+https://link.exlibris.lunabee.ovh)"
ALLOWED_HOSTS: frozenset[str] = frozenset(
    {"inventaire.io", "commons.wikimedia.org", "upload.wikimedia.org", "thumb.wikimedia.org"}
)
"""The only hosts the service reads, over https: inventaire.io, and Wikimedia for the images an
entity names there. Any other URL, first or reached by a redirect, is refused.

Wikimedia's chains, seen with `curl -sIL` on 2026-11-18 for `Special:FilePath/<file>?width=…`:
commons.wikimedia.org (302) → commons.wikimedia.org (301) → thumb.wikimedia.org for one file, and
→ upload.wikimedia.org for another."""

_logger: logging.Logger = logging.getLogger(__name__)


class Unreachable(Exception):
    """inventaire.io, or the host of an image, did not answer in time or answered with an error of
    its own: worth asking again later, unlike an object it says it does not have."""


class Refused(Exception):
    """A URL outside `ALLOWED_HOSTS`, asked for or redirected to: never read, whatever it holds,
    and not worth asking again."""


class _AllowedRedirects(HTTPRedirectHandler):
    """Follows a redirect only to a URL `is_allowed` accepts, checked again at every hop."""

    def redirect_request(
        self,
        req: Request,
        fp: Any,
        code: int,
        msg: str,
        headers: Any,
        newurl: str
    ) -> Request | None:
        if not is_allowed(newurl):
            raise Refused(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


_OPENER: OpenerDirector = build_opener(_AllowedRedirects)


def is_allowed(url: str) -> bool:
    """Whether `url` is https on one of `ALLOWED_HOSTS`, on the default port."""
    try:
        parts: SplitResult = urlsplit(url)
        return parts.scheme == "https" and parts.hostname in ALLOWED_HOSTS and parts.port in (None, 443)
    except ValueError:
        return False


class Inventaire:
    """A client of `https://inventaire.io/api`, with short timeouts and no cookie."""

    def __init__(
        self,
        base_url: str = "https://inventaire.io",
        timeout: float = 3.0,
        image_timeout: float = 5.0,
        image_byte_limit: int = 8 * 1024 * 1024
    ) -> None:
        self.base_url: str = base_url
        self._timeout: float = timeout
        self._image_timeout: float = image_timeout
        self._image_byte_limit: int = image_byte_limit

    def get(self, endpoint: str, query: dict[str, str]) -> dict[str, Any] | None:
        """Reads one endpoint, path style.

        Args:
            endpoint: The endpoint under `/api/`, e.g. `entities/by-uris`.
            query: The query, encoded here.

        Returns:
            The decoded JSON, or `None` when inventaire.io answers that the object is missing or
            may not be shown (any 4xx).

        Raises:
            Unreachable: On a timeout, a network error, a 5xx, a body that is not JSON, or a
                redirect away from inventaire.io.
        """
        url: str = f"{self.base_url}/api/{endpoint}?{urlencode(query)}"
        try:
            body: bytes = self._read(url, self._timeout, limit=None)
        except Refused as error:
            raise Unreachable(url) from error
        except HTTPError as error:
            _logger.info("inventaire.io GET %s -> %d", url, error.code)
            if 400 <= error.code < 500:
                return None
            raise Unreachable(url) from error
        try:
            payload: Any = json.loads(body)
        except ValueError as error:
            raise Unreachable(url) from error
        _logger.info("inventaire.io GET %s -> 200", url)
        return payload if isinstance(payload, dict) else None

    def image(self, url: str) -> bytes:
        """Downloads an image, from inventaire.io or from the host an entity names (Wikimedia).

        Raises:
            Unreachable: On any failure, or past the size limit.
            Refused: For a URL, or a redirect, outside `ALLOWED_HOSTS`.
        """
        try:
            body: bytes = self._read(url, self._image_timeout, limit=self._image_byte_limit)
        except HTTPError as error:
            _logger.info("image GET %s -> %d", url, error.code)
            raise Unreachable(url) from error
        _logger.info("image GET %s -> 200 (%d bytes)", url, len(body))
        return body

    @staticmethod
    def _read(url: str, timeout: float, limit: int | None) -> bytes:
        if not is_allowed(url):
            raise Refused(url)
        request: Request = Request(url, headers={"User-Agent": USER_AGENT})
        try:
            with _OPENER.open(request, timeout=timeout) as response:
                body: bytes = response.read() if limit is None else response.read(limit + 1)
        except (HTTPError, Refused):
            raise
        except (URLError, HTTPException, OSError) as error:
            _logger.warning("GET %s failed: %s", url, error)
            raise Unreachable(url) from error
        if limit is not None and len(body) > limit:
            raise Unreachable(f"{url} is larger than {limit} bytes")
        return body
