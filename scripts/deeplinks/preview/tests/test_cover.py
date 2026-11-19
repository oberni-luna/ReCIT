import io
import os
import tempfile
import unittest
import warnings
from pathlib import Path

from PIL import Image

from app.cover import ORIGIN, SIZE, Covers, CoverUnavailable, compose_image
from app.inventaire import Refused, Unreachable

ASSETS: Path = Path(__file__).resolve().parent.parent / "assets"
HASH: str = "33f0dc663d17e632aa8d36392bf2342b4e96d9bd"
RED: tuple[int, int, int] = (200, 30, 30)


def png(size: tuple[int, int], color: tuple[int, int, int], mode: str = "RGB") -> bytes:
    buffer: io.BytesIO = io.BytesIO()
    Image.new(mode, size, color if mode == "RGB" else 0).save(buffer, format="PNG")
    return buffer.getvalue()


class StubInventaire:
    base_url: str = "https://inventaire.io"

    def __init__(self, body: bytes | None, redirects_away: bool = False) -> None:
        self.body: bytes | None = body
        self.redirects_away: bool = redirects_away
        self.downloads: list[str] = []

    def image(self, url: str) -> bytes:
        self.downloads.append(url)
        if self.redirects_away:
            raise Refused("https://example.org/cover.jpg")
        if self.body is None:
            raise Unreachable(url)
        return self.body


class ComposeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.background: Image.Image = Image.open(ASSETS / "background.png").convert("RGB")

    def test_lays_the_cover_in_the_middle_of_the_background(self) -> None:
        image: Image.Image = compose_image(self.background, Image.new("RGB", (600, 988), RED))

        self.assertEqual(image.size, (1200, 630))
        self.assertEqual(image.getpixel((600, 315)), RED)
        self.assertEqual(image.getpixel((ORIGIN[0] + 10, ORIGIN[1] + 10)), RED)

    def test_rounds_the_corners(self) -> None:
        image: Image.Image = compose_image(self.background, Image.new("RGB", SIZE, RED))

        self.assertNotEqual(image.getpixel(ORIGIN), RED)

    def test_shadows_below_the_cover(self) -> None:
        image: Image.Image = compose_image(self.background, Image.new("RGB", SIZE, RED))
        below: tuple[int, int] = (600, ORIGIN[1] + SIZE[1])

        self.assertLess(sum(image.getpixel(below)), sum(self.background.getpixel(below)))


class CoversTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory: tempfile.TemporaryDirectory[str] = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)

    def covers(self, inventaire: StubInventaire, max_covers: int = 10) -> Covers:
        return Covers(Path(self.directory.name), ASSETS / "background.png", inventaire, max_covers)

    def test_composes_an_inventaire_cover_once_under_its_hash(self) -> None:
        inventaire: StubInventaire = StubInventaire(png((600, 900), RED))
        covers: Covers = self.covers(inventaire)

        key: str | None = covers.compose(f"/img/entities/{HASH}")
        again: str | None = covers.compose(f"/img/entities/{HASH}")

        self.assertEqual((key, again), (HASH, HASH))
        self.assertEqual(inventaire.downloads, [f"https://inventaire.io/img/entities/680x1020/{HASH}"])
        path: Path | None = covers.file(HASH)
        self.assertIsNotNone(path)
        with Image.open(path) as image:
            self.assertEqual((image.format, image.mode, image.size), ("JPEG", "RGB", (1200, 630)))
            self.assertTrue(image.info.get("progressive"))

    def test_keys_an_absolute_cover_by_its_url(self) -> None:
        url: str = "https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg?width=1280"
        inventaire: StubInventaire = StubInventaire(png((400, 600), RED))

        key: str | None = self.covers(inventaire).compose(url)

        self.assertRegex(key, r"^[0-9a-f]{40}$")
        self.assertEqual(inventaire.downloads, [url])

    def test_gives_up_on_covers_it_cannot_have(self) -> None:
        for url, body in (
            (f"/img/entities/{HASH}", None),
            (f"/img/entities/{HASH}", b"not an image")
        ):
            with self.subTest(url=url, body=body):
                with self.assertRaises(CoverUnavailable):
                    self.covers(StubInventaire(body)).compose(url)

    def test_gives_up_for_good_on_covers_outside_the_allowed_hosts_without_downloading_them(self) -> None:
        for url in (
            "http://inventaire.io/img/entities/cover.jpg",
            "https://example.org/cover.jpg",
            "https://inventaire.io.example.org/cover.jpg",
            "https://commons.wikimedia.org:8443/cover.jpg",
            "file:///etc/passwd"
        ):
            with self.subTest(url=url):
                inventaire: StubInventaire = StubInventaire(png((10, 10), RED))

                self.assertIsNone(self.covers(inventaire).compose(url))
                self.assertEqual(inventaire.downloads, [])

    def test_gives_up_for_good_on_a_cover_that_redirects_outside_the_allowed_hosts(self) -> None:
        inventaire: StubInventaire = StubInventaire(png((10, 10), RED), redirects_away=True)

        with self.assertLogs("app.cover", "WARNING"):
            self.assertIsNone(self.covers(inventaire).compose(f"/img/entities/{HASH}"))

    def test_refuses_images_too_large_to_decode_from_their_header(self) -> None:
        for size in ((10_000, 10_000), (7_000, 7_000)):
            body: bytes = png(size, RED, mode="1")
            with self.subTest(size=size, bytes=len(body)):
                self.assertLess(len(body), 100_000)
                with warnings.catch_warnings():
                    warnings.simplefilter("ignore", Image.DecompressionBombWarning)
                    with self.assertRaises(CoverUnavailable):
                        self.covers(StubInventaire(body)).compose(f"/img/entities/{HASH}")

    def test_keeps_at_most_max_covers_deleting_the_oldest_written(self) -> None:
        covers: Covers = self.covers(StubInventaire(png((40, 60), RED)), max_covers=2)
        oldest: str = "a" * 40
        middle: str = "b" * 40
        newest: str = "c" * 40

        covers.compose(f"/img/entities/{oldest}")
        covers.compose(f"/img/entities/{middle}")
        os.utime(Path(self.directory.name) / f"{oldest}.jpg", (0, 0))
        covers.compose(f"/img/entities/{newest}")

        self.assertIsNone(covers.file(oldest))
        self.assertIsNotNone(covers.file(middle))
        self.assertIsNotNone(covers.file(newest))

    def test_deletes_the_least_recently_used_rather_than_the_oldest_written(self) -> None:
        covers: Covers = self.covers(StubInventaire(png((40, 60), RED)), max_covers=2)
        popular: str = "a" * 40
        forgotten: str = "b" * 40
        newest: str = "c" * 40
        covers.compose(f"/img/entities/{popular}")
        covers.compose(f"/img/entities/{forgotten}")
        os.utime(Path(self.directory.name) / f"{popular}.jpg", (0, 0))
        os.utime(Path(self.directory.name) / f"{forgotten}.jpg", (1, 1))

        served: Path | None = covers.file(popular)
        covers.compose(f"/img/entities/{newest}")

        self.assertIsNotNone(served)
        self.assertIsNotNone(covers.file(popular))
        self.assertIsNone(covers.file(forgotten))

    def test_a_page_naming_a_cover_marks_it_used(self) -> None:
        inventaire: StubInventaire = StubInventaire(png((40, 60), RED))
        covers: Covers = self.covers(inventaire)
        covers.compose(f"/img/entities/{HASH}")
        os.utime(Path(self.directory.name) / f"{HASH}.jpg", (0, 0))

        covers.compose(f"/img/entities/{HASH}")

        self.assertGreater((Path(self.directory.name) / f"{HASH}.jpg").stat().st_mtime, 1)
        self.assertEqual(len(inventaire.downloads), 1)

    def test_serves_only_keys_it_made(self) -> None:
        covers: Covers = self.covers(StubInventaire(None))

        self.assertIsNone(covers.file(HASH))
        self.assertIsNone(covers.file("../../etc/passwd"))
