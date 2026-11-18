import unittest
from typing import Any

from app import tags
from app.tags import Preview
from tests.support import (
    AUTHOR_URI,
    EDITION_ISBN,
    LIST_ID,
    SHELF_ID,
    WORK_URI,
    fixture
)

NNBSP: str = " "
NBSP: str = " "
ETRANGER_COVER: str = "/img/entities/33f0dc663d17e632aa8d36392bf2342b4e96d9bd"


class TagsTests(unittest.TestCase):
    def test_an_edition_names_its_work_authors_and_publisher(self) -> None:
        preview: Preview | None = tags.of_entity(fixture("entities_edition"), EDITION_ISBN)

        self.assertEqual(
            preview,
            tags.Preview("L'Étranger", "Albert Camus · Éditions Gallimard, sur Ex-libris", ETRANGER_COVER)
        )

    def test_a_work_names_its_authors(self) -> None:
        preview: Preview | None = tags.of_entity(fixture("entities_work"), WORK_URI)

        self.assertEqual(preview.title, "L'Étranger")
        self.assertEqual(preview.description, "Albert Camus, sur Ex-libris")
        self.assertEqual(preview.cover_url, "/img/entities/969690a52b3a28628b52ab569d501880b1b0e62e")

    def test_an_author_has_a_name_a_description_and_no_cover(self) -> None:
        preview: Preview | None = tags.of_entity(fixture("entities_author"), AUTHOR_URI)

        self.assertEqual(
            preview,
            tags.Preview("Albert Camus sur Ex-libris", "écrivain, philosophe et journaliste français")
        )

    def test_a_missing_entity_has_no_preview(self) -> None:
        self.assertIsNone(tags.of_entity(fixture("entities_not_found"), "wd:Q999999999999"))

    def test_a_label_falls_back_to_english_then_the_original_language(self) -> None:
        payload: dict[str, Any] = {"entities": {"wd:Q1": {"type": "human", "originalLang": "de", "labels": {"de": "Kafka"}}}}
        self.assertEqual(tags.of_entity(payload, "wd:Q1").title, "Kafka sur Ex-libris")

        payload["entities"]["wd:Q1"]["labels"]["en"] = "Franz Kafka"
        self.assertEqual(tags.of_entity(payload, "wd:Q1").title, "Franz Kafka sur Ex-libris")

    def test_an_item_says_whose_it_is(self) -> None:
        item: dict[str, Any] = fixture("items_by_ids")["items"][0]

        preview: Preview | None = tags.of_item(item, "lea")

        self.assertEqual(preview.title, "Les contraceptés - Enquête sur le dernier tabou")
        self.assertEqual(preview.description, "Guillaume Daudin, Stéphane Jourdain · chez lea, sur Ex-libris")
        self.assertEqual(preview.cover_url, "/img/entities/7ec6ca27d6677d6a42107fc7d76d0afdf69c8e39")

    def test_a_list_element_says_which_list_it_is_in(self) -> None:
        entity_list: dict[str, Any] = fixture("lists_by_element_id")["list"]

        preview: Preview | None = tags.of_list_element(entity_list, "remi", fixture("entities_work"), WORK_URI)

        self.assertEqual(preview.title, "L'Étranger")
        self.assertEqual(
            preview.description,
            f"Dans la liste «{NNBSP}Pour changer le monde{NNBSP}» de remi, sur Ex-libris"
        )
        self.assertIsNotNone(preview.cover_url)

    def test_an_author_in_a_list_has_no_cover(self) -> None:
        entity_list: dict[str, Any] = fixture("lists_by_element_id")["list"]

        preview: Preview | None = tags.of_list_element(entity_list, "remi", fixture("entities_author"), AUTHOR_URI)

        self.assertEqual(preview.title, "Albert Camus")
        self.assertIsNone(preview.cover_url)

    def test_a_list_counts_its_works(self) -> None:
        entity_list: dict[str, Any] = fixture("lists_by_ids")["lists"][LIST_ID]

        preview: Preview | None = tags.of_list(entity_list, "remi")

        self.assertEqual(
            preview,
            tags.Preview("Pour changer le monde", f"Une liste de remi sur Ex-libris · 8{NBSP}œuvres")
        )

    def test_counts_agree_in_number(self) -> None:
        one_work: dict[str, Any] = {"name": "Seule", "type": "work", "totalElements": 1}
        authors: dict[str, Any] = {"name": "Elles", "type": "human", "totalElements": 2}
        empty: dict[str, Any] = {"name": "Vide", "type": "work", "totalElements": 0}

        self.assertEqual(tags.of_list(one_work, "Léa").description, f"Une liste de Léa sur Ex-libris · 1{NBSP}œuvre")
        self.assertEqual(
            tags.of_list(authors, "Léa").description,
            f"Une liste de Léa sur Ex-libris · 2{NBSP}auteur·ices"
        )
        self.assertEqual(tags.of_list(empty, "Léa").description, "Une liste de Léa sur Ex-libris")

    def test_a_shelf_counts_its_books(self) -> None:
        shelf: dict[str, Any] = fixture("shelves_by_ids")["shelves"][SHELF_ID]

        preview: Preview | None = tags.of_shelf(shelf, "remi")

        self.assertEqual(
            preview,
            tags.Preview("À lire cet été", f"Une étagère de remi sur Ex-libris · 14{NBSP}livres")
        )

    def test_a_reader_shows_their_bio(self) -> None:
        user: dict[str, Any] = fixture("users_by_usernames_lea")["users"]["lea"]

        preview: Preview | None = tags.of_user(user, list_count=0)

        self.assertEqual(
            preview,
            tags.Preview("lea sur Ex-libris", "Lectrice de polars, prête volontiers ses livres")
        )

    def test_a_reader_without_a_bio_shows_their_counts(self) -> None:
        remi: dict[str, Any] = fixture("users_by_usernames_remi")["users"]["remi"]
        sam: dict[str, Any] = fixture("users_by_usernames_sam")["users"]["sam"]

        self.assertEqual(tags.of_user(remi, list_count=2).description, f"125{NBSP}livres · 2{NBSP}listes")
        self.assertEqual(tags.of_user(sam, list_count=0).description, f"71{NBSP}livres")
        self.assertEqual(tags.of_user(remi, list_count=None).description, f"125{NBSP}livres")
        self.assertEqual(tags.of_user({"username": "Vide"}, list_count=0).description, tags.GENERIC.description)

    def test_a_group_shows_its_description_else_its_members(self) -> None:
        described: Preview | None = tags.of_group(fixture("groups_by_slug")["group"])
        bare: Preview | None = tags.of_group(fixture("groups_by_slug_no_description")["group"])

        self.assertEqual(described.title, "Polar & noir sur Ex-libris")
        self.assertEqual(
            described.description,
            f"On échange nos polars préférés, et on en parle le jeudi{NNBSP}!"
        )
        self.assertEqual(bare, tags.Preview("Club de lecture sur Ex-libris", f"1{NBSP}membre"))

    def test_elides_de_before_a_vowel(self) -> None:
        shelf: dict[str, Any] = fixture("shelves_by_ids")["shelves"][SHELF_ID]
        entity_list: dict[str, Any] = fixture("lists_by_ids")["lists"][LIST_ID]

        self.assertTrue(tags.of_shelf(shelf, "Émile").description.startswith("Une étagère d'Émile sur"))
        self.assertTrue(tags.of_list(entity_list, "ines").description.startswith("Une liste d'ines sur"))
        self.assertTrue(tags.of_list(entity_list, "Hugo").description.startswith("Une liste de Hugo sur"))
        self.assertTrue(tags.of_list(entity_list, "Yann").description.startswith("Une liste de Yann sur"))
        self.assertTrue(tags.of_list(entity_list, "_x").description.startswith("Une liste de _x sur"))

    def test_counts_a_group_s_admins_with_its_members(self) -> None:
        group: dict[str, Any] = {**fixture("groups_by_slug")["group"], "description": ""}

        self.assertEqual(tags.of_group(group).description, f"4{NBSP}membres")

    def test_typesets_titles_the_french_way(self) -> None:
        item: dict[str, Any] = {"snapshot": {"entity:title": "Riche, pourquoi pas toi ?", "entity:authors": "Marion Montaigne"}}

        preview: Preview | None = tags.of_item(item, "Léa")

        self.assertEqual(preview.title, f"Riche, pourquoi pas toi{NNBSP}?")
        self.assertEqual(preview.description, "Marion Montaigne · chez Léa, sur Ex-libris")

    def test_groups_thousands_and_keeps_descriptions_short(self) -> None:
        user: dict[str, Any] = {"username": "Léa", "bio": "mot " * 100, "snapshot": {"public": {"items:count": 1234}}}

        self.assertTrue(tags.of_user(user, 0).description.endswith("mot…"))
        self.assertLessEqual(len(tags.of_user(user, 0).description), 200)
        self.assertEqual(
            tags.of_user({**user, "bio": ""}, 0).description,
            f"1{NNBSP}234{NBSP}livres"
        )

    def test_a_bio_on_several_lines_reads_as_one(self) -> None:
        user: dict[str, Any] = {"username": "Léa", "bio": "Lectrice.\n\nPolars   et BD"}

        self.assertEqual(tags.of_user(user, 0).description, "Lectrice. Polars et BD")
