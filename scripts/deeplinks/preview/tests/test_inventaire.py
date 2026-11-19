import unittest
from unittest.mock import patch
from urllib.request import Request

from app.inventaire import Inventaire, Refused, Unreachable, _AllowedRedirects, is_allowed


class AllowedHostsTests(unittest.TestCase):
    def test_allows_https_on_inventaire_and_wikimedia_only(self) -> None:
        for url in (
            "https://inventaire.io/img/entities/680x1020/abc",
            "https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/a/ab/Cover.jpg",
            "https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ab/Cover.jpg/960px-Cover.jpg"
        ):
            with self.subTest(url=url):
                self.assertTrue(is_allowed(url))
        for url in (
            "http://inventaire.io/api",
            "https://example.org/",
            "https://inventaire.io.example.org/",
            "https://inventaire.io:8080/",
            "https://inventaire.io:abc/",
            "file:///etc/passwd",
            "ftp://upload.wikimedia.org/"
        ):
            with self.subTest(url=url):
                self.assertFalse(is_allowed(url))

    def test_checks_every_redirect_hop(self) -> None:
        handler: _AllowedRedirects = _AllowedRedirects()
        request: Request = Request("https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg")
        allowed: str = "https://upload.wikimedia.org/wikipedia/commons/a/ab/Cover.jpg"

        followed: Request | None = handler.redirect_request(request, None, 302, "Found", {}, allowed)

        self.assertIsNotNone(followed)
        self.assertEqual(followed.full_url, allowed)
        for refused in ("http://upload.wikimedia.org/x.jpg", "https://169.254.169.254/latest", "file:///etc/passwd"):
            with self.subTest(refused=refused):
                with self.assertRaises(Refused):
                    handler.redirect_request(request, None, 302, "Found", {}, refused)

    def test_refuses_a_url_outside_the_allowed_hosts_before_connecting(self) -> None:
        with self.assertRaises(Refused):
            Inventaire().image("https://127.0.0.1:8620/og/ex-libris.jpg")

    def test_an_api_read_redirected_away_counts_as_unreachable(self) -> None:
        with patch.object(Inventaire, "_read", side_effect=Refused("https://example.org/")):
            with self.assertRaises(Unreachable):
                Inventaire().get("entities/by-uris", {"uris": "wd:Q1"})

    def test_refused_is_not_unreachable(self) -> None:
        self.assertFalse(issubclass(Refused, Unreachable))
