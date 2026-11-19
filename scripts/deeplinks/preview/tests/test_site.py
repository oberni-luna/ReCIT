import unittest
from pathlib import Path

from app.cover import CoverUnavailable
from app.site import PAGE_MAX_AGE, RETRY_MAX_AGE, Response, Site
from tests.support import EDITION_ISBN, LIST_ID, RecordedInventaire

ASSETS: Path = Path(__file__).resolve().parent.parent / "assets"
BASE_URL: str = "https://link.exlibris.lunabee.ovh"
KEY: str = "33f0dc663d17e632aa8d36392bf2342b4e96d9bd"


class StubCovers:
    def __init__(self, available: bool = True, allowed: bool = True) -> None:
        self.available: bool = available
        self.allowed: bool = allowed

    def compose(self, cover_url: str) -> str | None:
        if not self.allowed:
            return None
        if not self.available:
            raise CoverUnavailable(cover_url)
        return KEY

    def file(self, key: str) -> Path | None:
        return ASSETS / "favicon.png" if key == KEY else None


class SiteTests(unittest.TestCase):
    def site(self, inventaire: RecordedInventaire | None = None, covers: StubCovers | None = None) -> Site:
        return Site(BASE_URL, inventaire or RecordedInventaire(), covers or StubCovers(), ASSETS)

    def page(self, path: str, site: Site | None = None) -> tuple[Response, str]:
        response: Response = (site or self.site()).respond(path)
        self.assertEqual(response.status, 200)
        self.assertEqual(response.content_type, "text/html; charset=utf-8")
        return response, response.body.decode()

    def test_a_book_page_shows_its_composed_cover(self) -> None:
        response: Response
        html: str
        response, html = self.page(f"/entity/{EDITION_ISBN}")

        self.assertIn('content="L&#x27;Étranger"', html)
        self.assertIn(f'property="og:image" content="{BASE_URL}/og/cover/{KEY}.jpg"', html)
        self.assertIn(f'property="og:url" content="{BASE_URL}/entity/{EDITION_ISBN}"', html)
        self.assertIn(f'href="https://inventaire.io/entity/{EDITION_ISBN}"', html)
        self.assertEqual(response.max_age, PAGE_MAX_AGE)

    def test_a_list_page_shows_the_static_image(self) -> None:
        html: str
        _, html = self.page(f"/lists/{LIST_ID}")

        self.assertIn('property="og:title" content="Pour changer le monde"', html)
        self.assertIn(f'property="og:image" content="{BASE_URL}/og/ex-libris.jpg"', html)

    def test_a_link_that_does_not_parse_gets_the_generic_page_without_a_read(self) -> None:
        inventaire: RecordedInventaire = RecordedInventaire()

        html: str

        _, html = self.page("/entity/wd:Q1%7Cwd:Q2", self.site(inventaire))

        self.assertIn('property="og:title" content="Ex-libris"', html)
        self.assertIn('property="og:description" content="Vos livres, et ceux qui circulent"', html)
        self.assertIn('href="https://inventaire.io/entity/wd:Q1%7Cwd:Q2"', html)
        self.assertEqual(inventaire.requests, [])

    def test_an_unreachable_inventaire_gets_the_generic_page_for_a_minute(self) -> None:
        with self.assertLogs("app.site", "WARNING"):
            response: Response
            html: str
            response, html = self.page(f"/entity/{EDITION_ISBN}", self.site(RecordedInventaire(reachable=False)))

        self.assertIn('property="og:title" content="Ex-libris"', html)
        self.assertEqual(response.max_age, RETRY_MAX_AGE)

    def test_a_cover_it_cannot_have_falls_back_to_the_static_image(self) -> None:
        with self.assertLogs("app.site", "WARNING"):
            response: Response
            html: str
            response, html = self.page(f"/entity/{EDITION_ISBN}", self.site(covers=StubCovers(available=False)))

        self.assertIn('content="L&#x27;Étranger"', html)
        self.assertIn(f'content="{BASE_URL}/og/ex-libris.jpg"', html)
        self.assertEqual(response.max_age, RETRY_MAX_AGE)

    def test_a_cover_on_a_refused_host_gets_the_static_image_for_the_hour(self) -> None:
        response: Response
        html: str
        response, html = self.page(f"/entity/{EDITION_ISBN}", self.site(covers=StubCovers(allowed=False)))

        self.assertIn(f'content="{BASE_URL}/og/ex-libris.jpg"', html)
        self.assertEqual(response.max_age, PAGE_MAX_AGE)

    def test_serves_the_images_and_nothing_else_under_og(self) -> None:
        site: Site = self.site()

        self.assertEqual(site.respond("/og/ex-libris.jpg").content_type, "image/jpeg")
        self.assertEqual(site.respond("/og/apple-touch-icon.png").content_type, "image/png")
        self.assertEqual(site.respond(f"/og/cover/{KEY}.jpg").content_type, "image/jpeg")
        self.assertEqual(site.respond("/og/cover/nope.jpg").status, 404)
        self.assertEqual(site.respond("/og/background.png").status, 404)
        self.assertEqual(site.respond("/og/ex-libris.png").status, 404)
        self.assertEqual(site.respond("/og/../server.py").status, 404)
