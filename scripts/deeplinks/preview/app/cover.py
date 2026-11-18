"""A book's preview image: its cover on the night green background, a 1200 × 630 JPEG, made once.

The layout is Figma's (`Social Preview`): the cover 340 × 510 at (430, 60), corners of 8, under
the « Shadow/Painted Book » shadow — black at 16 %, 1.5 down, 1.5 of blur.
"""

import hashlib
import io
import logging
import os
import re
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps

from .inventaire import Inventaire, Refused, Unreachable, is_allowed

ORIGIN: tuple[int, int] = (430, 60)
SIZE: tuple[int, int] = (340, 510)
CORNER_RADIUS: int = 8
SHADOW_OPACITY: float = 0.16
SHADOW_OFFSET: float = 1.5
SHADOW_BLUR: float = 1.5
JPEG_QUALITY: int = 85
MAX_COVER_PIXELS: int = 40_000_000
"""Past this, a cover is refused before it is decoded; Pillow itself refuses twice as many."""
MAX_COVERS: int = 10_000
"""The cover cache holds at most this many images, about 0.5 GB at 50 KB each: writing one more
deletes the one least recently used — written, named by a page or served —, which is made again
the next time a page names it."""

_SUPERSAMPLING: int = 4
_SHADOW_MARGIN: int = 4
_INVENTAIRE_IMAGE: re.Pattern[str] = re.compile(r"/img/entities/([0-9a-f]{40})")
_KEY: re.Pattern[str] = re.compile(r"[0-9a-f]{40}")

_logger: logging.Logger = logging.getLogger(__name__)

Image.MAX_IMAGE_PIXELS = MAX_COVER_PIXELS


class CoverUnavailable(Exception):
    """The cover could not be downloaded or read: the page falls back to the static image."""


class Covers:
    """Book images, written once to `directory` under their cover's key and never rewritten, at
    most `max_covers` of them.

    The key is inventaire.io's own hash for its images, the SHA-1 of the URL for the others
    (Wikimedia): 40 hexadecimal digits either way.
    """

    def __init__(
        self,
        directory: Path,
        background: Path,
        inventaire: Inventaire,
        max_covers: int = MAX_COVERS
    ) -> None:
        self._directory: Path = directory
        self._background: Image.Image = Image.open(background).convert("RGB")
        self._inventaire: Inventaire = inventaire
        self._max_covers: int = max_covers

    def compose(self, cover_url: str) -> str | None:
        """The key of the image made of `cover_url`, made now unless it already is.

        Args:
            cover_url: An entity's image as inventaire.io gives it: `/img/entities/<hash>`, or an
                absolute URL.

        Returns:
            The key, or `None` when the cover lies, or redirects, outside the hosts the service
            reads: a miss for good, not worth asking again.

        Raises:
            CoverUnavailable: When the cover cannot be had now.
        """
        source: tuple[str, str] | None = self._source(cover_url)
        if source is None:
            _logger.warning("cover %s is not on an allowed host", cover_url)
            return None
        key, url = source
        path: Path = self._directory / f"{key}.jpg"
        if _mark_used(path):
            return key
        try:
            cover: Image.Image = Image.open(io.BytesIO(self._inventaire.image(url)))
            if cover.width * cover.height > MAX_COVER_PIXELS:
                raise CoverUnavailable(f"{url} is {cover.width} × {cover.height}")
            cover.draft("RGB", (SIZE[0] * 2, SIZE[1] * 2))
            image: Image.Image = compose_image(self._background, cover)
        except Refused as error:
            _logger.warning("cover %s redirects outside the allowed hosts: %s", url, error)
            return None
        except (Unreachable, OSError, Image.DecompressionBombError) as error:
            raise CoverUnavailable(url) from error
        _write_jpeg(image, path)
        _logger.info("cover %s composed from %s", key, url)
        self._prune()
        return key

    def file(self, key: str) -> Path | None:
        """The image saved under `key`, if `key` is one and it was made."""
        if not _KEY.fullmatch(key):
            return None
        path: Path = self._directory / f"{key}.jpg"
        return path if _mark_used(path) else None

    def _source(self, cover_url: str) -> tuple[str, str] | None:
        """The key and the URL to download, `None` for a URL outside the allowed hosts."""
        base_url: str = self._inventaire.base_url
        if match := _INVENTAIRE_IMAGE.fullmatch(cover_url):
            return match[1], f"{base_url}/img/entities/{SIZE[0] * 2}x{SIZE[1] * 2}/{match[1]}"
        absolute: str = f"{base_url}{cover_url}" if cover_url.startswith("/") else cover_url
        if not is_allowed(absolute):
            return None
        return hashlib.sha1(absolute.encode()).hexdigest(), absolute

    def _prune(self) -> None:
        """Deletes the least recently used images past `max_covers`. Runs only when one is written,
        which happens once per book: listing the folder then is cheap."""
        written: list[tuple[float, Path]] = []
        for path in self._directory.glob("*.jpg"):
            try:
                written.append((path.stat().st_mtime, path))
            except FileNotFoundError:
                continue
        for _, path in sorted(written)[: max(0, len(written) - self._max_covers)]:
            path.unlink(missing_ok=True)
            _logger.info("cover %s pruned", path.stem)


def compose_image(background: Image.Image, cover: Image.Image) -> Image.Image:
    """`cover`, filled into the slot and cropped to its 2:3, rounded and shadowed on `background`."""
    canvas: Image.Image = background.convert("RGBA")
    mask: Image.Image = _rounded_mask()
    canvas.alpha_composite(_shadow(mask), (ORIGIN[0] - _SHADOW_MARGIN, ORIGIN[1] - _SHADOW_MARGIN))
    filled: Image.Image = ImageOps.fit(cover.convert("RGB"), SIZE, Image.Resampling.LANCZOS).convert("RGBA")
    filled.putalpha(mask)
    canvas.alpha_composite(filled, ORIGIN)
    return canvas.convert("RGB")


def _rounded_mask() -> Image.Image:
    large: Image.Image = Image.new("L", (SIZE[0] * _SUPERSAMPLING, SIZE[1] * _SUPERSAMPLING), 0)
    ImageDraw.Draw(large).rounded_rectangle(
        (0, 0, large.width - 1, large.height - 1),
        radius=CORNER_RADIUS * _SUPERSAMPLING,
        fill=255
    )
    return large.resize(SIZE, Image.Resampling.LANCZOS)


def _shadow(mask: Image.Image) -> Image.Image:
    """Black under the cover's shape, moved down and blurred, `_SHADOW_MARGIN` wider each side."""
    alpha: Image.Image = Image.new("L", (SIZE[0] + 2 * _SHADOW_MARGIN, SIZE[1] + 2 * _SHADOW_MARGIN), 0)
    alpha.paste(mask.point(lambda value: round(value * SHADOW_OPACITY)), (_SHADOW_MARGIN, _SHADOW_MARGIN))
    alpha = alpha.transform(
        alpha.size,
        Image.Transform.AFFINE,
        (1, 0, 0, 0, 1, -SHADOW_OFFSET),
        resample=Image.Resampling.BILINEAR
    ).filter(ImageFilter.GaussianBlur(SHADOW_BLUR / 2))
    shadow: Image.Image = Image.new("RGBA", alpha.size, (0, 0, 0, 0))
    shadow.putalpha(alpha)
    return shadow


def _mark_used(path: Path) -> bool:
    """Whether the image at `path` exists, its modification time set to now if so: `_prune` reads
    it as the image's last use."""
    try:
        os.utime(path)
    except FileNotFoundError:
        return False
    return True


def _write_jpeg(image: Image.Image, path: Path) -> None:
    """Writes beside `path`, then moves into place: a reader never sees half an image."""
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, suffix=".jpg.tmp")
    with os.fdopen(descriptor, "wb") as file:
        image.save(file, format="JPEG", quality=JPEG_QUALITY, progressive=True, optimize=True)
    os.replace(temporary, path)
