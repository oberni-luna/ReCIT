import unittest

from app.paths import Entity, EntityList, Group, InventoryItem, Link, Shelf, User, parse

ID: str = "9c8b7a6f5e4d3c2b1a0f9e8d7c6b5a49"
OTHER_ID: str = "8b7a6f5e4d3c2b1a0f9e8d7c6b5a4938"


class ParseTests(unittest.TestCase):
    def test_reads_every_kind_of_link(self) -> None:
        self.assertEqual(parse("/entity/isbn:9782070360024"), Entity("isbn:9782070360024"))
        self.assertEqual(parse("/entity/wd:Q163297"), Entity("wd:Q163297"))
        self.assertEqual(parse(f"/entity/inv:{ID}"), Entity(f"inv:{ID}"))
        self.assertEqual(parse(f"/items/{ID}"), InventoryItem(ID))
        self.assertEqual(parse(f"/lists/{ID}"), EntityList(ID))
        self.assertEqual(parse(f"/lists/{ID}/element/{OTHER_ID}"), EntityList(ID, OTHER_ID))
        self.assertEqual(parse(f"/shelves/{ID}"), Shelf(ID))
        self.assertEqual(parse("/users/Lea_42"), User("Lea_42"))
        self.assertEqual(parse("/groups/polar-et-noir"), Group("polar-et-noir"))

    def test_decodes_segments_before_matching_them(self) -> None:
        self.assertEqual(parse("/entity/wd%3AQ1"), Entity("wd:Q1"))
        self.assertEqual(parse("/users/L%C3%A9a"), User("Léa"))
        self.assertEqual(
            parse("/groups/caf%C3%A9-lecture"),
            Group("café-lecture")
        )

    def test_refuses_what_would_reach_a_query_string_as_something_else(self) -> None:
        self.assertIsNone(parse("/entity/wd:Q1%7Cwd:Q2"))
        self.assertIsNone(parse("/entity/wd:Q1|wd:Q2"))
        self.assertIsNone(parse("/entity/wd:Q1%26lang=en"))
        self.assertIsNone(parse("/users/L%C3%A9a%26x"))
        self.assertIsNone(parse("/groups/polar%20noir"))
        self.assertIsNone(parse("/entity/wd%2FQ1"))

    def test_refuses_ids_that_are_not_couchdb_ids(self) -> None:
        self.assertIsNone(parse(f"/items/{ID.upper()}"))
        self.assertIsNone(parse(f"/items/{ID[:-1]}"))
        self.assertIsNone(parse(f"/shelves/{ID}0"))
        self.assertIsNone(parse(f"/lists/{ID}/element/nope"))
        self.assertIsNone(parse(f"/lists/{ID}/elements/{OTHER_ID}"))

    def test_follows_inventaire_rules_for_usernames_and_slugs(self) -> None:
        self.assertIsNone(parse("/users/a"))
        self.assertIsNone(parse("/users/abcdefghijklmnopqrstu"))
        self.assertEqual(parse("/users/abcdefghijklmnopqrst"), User("abcdefghijklmnopqrst"))
        self.assertEqual(parse("/groups/polar-noir.2"), Group("polar-noir.2"))
        self.assertIsNone(parse("/groups/polar-noir.2.3"))
        self.assertIsNone(parse("/groups/polar_noir"))

    def test_refuses_other_shapes(self) -> None:
        for path in ("/", "/entity", "/entity/", "/entity/wd:Q1/more", "/works/wd:Q1", "/users/%FF%FE"):
            with self.subTest(path=path):
                self.assertIsNone(parse(path))

    def test_ignores_query_and_empty_segments(self) -> None:
        self.assertEqual(parse("/entity/wd:Q1?lang=en"), Entity("wd:Q1"))
        self.assertEqual(parse("/entity/wd:Q1/"), Entity("wd:Q1"))

    def test_gives_each_link_its_path_back(self) -> None:
        for path in (
            "/entity/wd:Q1",
            f"/items/{ID}",
            f"/lists/{ID}",
            f"/lists/{ID}/element/{OTHER_ID}",
            f"/shelves/{ID}",
            "/users/L%C3%A9a",
            "/groups/polar-noir.2"
        ):
            with self.subTest(path=path):
                link: Link | None = parse(path)
                self.assertIsNotNone(link)
                self.assertEqual(link.path, path)
