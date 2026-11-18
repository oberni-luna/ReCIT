import unittest

from app.page import PageURLs, render
from app.tags import Preview

URLS: PageURLs = PageURLs(
    page="https://link.exlibris.lunabee.ovh/entity/wd:Q1",
    image="https://link.exlibris.lunabee.ovh/og/ex-libris.jpg",
    favicon="https://link.exlibris.lunabee.ovh/og/favicon.png",
    apple_touch_icon="https://link.exlibris.lunabee.ovh/og/apple-touch-icon.png",
    inventaire="https://inventaire.io/entity/wd:Q1?a=1&b=2"
)


class RenderTests(unittest.TestCase):
    def test_carries_every_tag_a_preview_needs(self) -> None:
        html: str = render(Preview("L'Étranger", "Albert Camus, sur Ex-libris"), URLS)

        for tag in (
            '<meta property="og:title" content="L&#x27;Étranger">',
            '<meta property="og:description" content="Albert Camus, sur Ex-libris">',
            '<meta property="og:site_name" content="Ex-libris">',
            f'<meta property="og:url" content="{URLS.page}">',
            f'<meta property="og:image" content="{URLS.image}">',
            '<meta property="og:image:width" content="1200">',
            '<meta property="og:image:height" content="630">',
            '<meta property="og:image:type" content="image/jpeg">',
            '<meta name="twitter:card" content="summary_large_image">',
            '<meta name="robots" content="noindex">',
            f'<link rel="icon" type="image/png" href="{URLS.favicon}">',
            f'<link rel="apple-touch-icon" href="{URLS.apple_touch_icon}">',
            "<title>L&#x27;Étranger</title>",
            '<a href="https://inventaire.io/entity/wd:Q1?a=1&amp;b=2">'
        ):
            with self.subTest(tag=tag):
                self.assertIn(tag, html)

    def test_escapes_what_inventaire_returns(self) -> None:
        html: str = render(Preview('<script>alert("x")</script>', "a & b"), URLS)

        self.assertNotIn("<script>", html)
        self.assertIn("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;", html)
        self.assertIn('content="a &amp; b"', html)
