import unittest

from app.inventaire import Unreachable
from app.paths import Entity, EntityList, Group, InventoryItem, Shelf, User
from app.previews import read_preview
from app.tags import Preview
from tests.support import (
    EDITION_ISBN,
    ELEMENT_ID,
    GROUP_SLUG,
    ITEM_ID,
    LIST_ID,
    SHELF_ID,
    RecordedInventaire
)

MISSING_ID: str = "00000000000000000000000000000000"


class ReadPreviewTests(unittest.TestCase):
    def setUp(self) -> None:
        self.inventaire: RecordedInventaire = RecordedInventaire()

    def test_reads_a_book_in_one_request(self) -> None:
        preview: Preview | None = read_preview(Entity(EDITION_ISBN), self.inventaire)

        self.assertEqual(preview.title, "L'Étranger")
        self.assertEqual(len(self.inventaire.requests), 1)
        endpoint: str
        query: dict[str, str]
        endpoint, query = self.inventaire.requests[0]
        self.assertEqual(endpoint, "entities/by-uris")
        self.assertEqual(query["relatives"], "wdt:P629|wdt:P50|wdt:P58|wdt:P110|wdt:P6338|wdt:P123")

    def test_reads_an_item_and_its_owner(self) -> None:
        preview: Preview | None = read_preview(InventoryItem(ITEM_ID), self.inventaire)

        self.assertTrue(preview.description.endswith("· chez lea, sur Ex-libris"))

    def test_reads_a_list_and_its_creator(self) -> None:
        preview: Preview | None = read_preview(EntityList(LIST_ID), self.inventaire)

        self.assertEqual(preview.title, "Pour changer le monde")
        self.assertIn("remi", preview.description)

    def test_reads_a_list_element_its_list_and_its_book(self) -> None:
        preview: Preview | None = read_preview(EntityList(LIST_ID, ELEMENT_ID), self.inventaire)

        self.assertEqual(preview.title, "L'Étranger")
        self.assertIn("Pour changer le monde", preview.description)
        self.assertIsNotNone(preview.cover_url)

    def test_an_element_of_another_list_is_not_shown(self) -> None:
        self.assertIsNone(read_preview(EntityList(MISSING_ID, ELEMENT_ID), self.inventaire))

    def test_reads_a_shelf_and_its_owner(self) -> None:
        preview: Preview | None = read_preview(Shelf(SHELF_ID), self.inventaire)

        self.assertEqual(preview.title, "À lire cet été")

    def test_reads_a_reader_in_any_case_and_their_lists_without_a_bio(self) -> None:
        with_bio: Preview | None = read_preview(User("Lea"), self.inventaire)
        without_bio: Preview | None = read_preview(User("remi"), self.inventaire)

        self.assertEqual(with_bio.title, "lea sur Ex-libris")
        self.assertEqual(with_bio.description, "Lectrice de polars, prête volontiers ses livres")
        self.assertIn("2 listes", without_bio.description)
        self.assertEqual(
            [endpoint for endpoint, _ in self.inventaire.requests],
            ["users/by-usernames", "users/by-usernames", "lists/by-creators"]
        )

    def test_reads_a_group(self) -> None:
        preview: Preview | None = read_preview(Group(GROUP_SLUG), self.inventaire)

        self.assertEqual(preview.title, "Polar & noir sur Ex-libris")

    def test_missing_objects_have_no_preview(self) -> None:
        for link in (
            Entity("wd:Q999999999999"),
            InventoryItem(MISSING_ID),
            EntityList(MISSING_ID),
            Shelf(MISSING_ID),
            User("zzqqxxnobody"),
            Group("zzqqxxnobody")
        ):
            with self.subTest(link=link):
                self.assertIsNone(read_preview(link, self.inventaire))

    def test_a_list_not_public_has_no_preview(self) -> None:
        self.inventaire.answers[("lists/by-ids", LIST_ID)]["lists"][LIST_ID]["visibility"] = ["friends"]

        self.assertIsNone(read_preview(EntityList(LIST_ID), self.inventaire))

    def test_an_element_of_a_list_not_public_has_no_preview(self) -> None:
        self.inventaire.answers[("lists/by-element-id", ELEMENT_ID)]["list"]["visibility"] = ["friends"]

        self.assertIsNone(read_preview(EntityList(LIST_ID, ELEMENT_ID), self.inventaire))

    def test_an_item_not_public_has_no_preview(self) -> None:
        self.inventaire.answers[("items/by-ids", ITEM_ID)]["items"][0]["visibility"] = ["friends"]

        self.assertIsNone(read_preview(InventoryItem(ITEM_ID), self.inventaire))

    def test_a_shelf_not_public_has_no_preview(self) -> None:
        self.inventaire.answers[("shelves/by-ids", SHELF_ID)]["shelves"][SHELF_ID]["visibility"] = ["friends"]

        self.assertIsNone(read_preview(Shelf(SHELF_ID), self.inventaire))

    def test_an_unreachable_inventaire_is_said_so(self) -> None:
        with self.assertRaises(Unreachable):
            read_preview(Entity(EDITION_ISBN), RecordedInventaire(reachable=False))
