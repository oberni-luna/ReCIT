package studio.lunabee.nouveaurecit.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto

class DeepLinkTest {
    @Test
    fun an_entity_link_carries_its_uri_whatever_its_prefix() {
        assertEquals(DeepLink.Entity("isbn:9782070360024"), DeepLink.parse("https://link.exlibris.lunabee.ovh/entity/isbn:9782070360024"))
        assertEquals(DeepLink.Entity("wd:Q535"), DeepLink.parse("https://link.exlibris.lunabee.ovh/entity/wd:Q535"))
    }

    @Test
    fun another_host_another_path_or_a_uri_without_a_prefix_is_not_a_link() {
        listOf(
            "https://inventaire.io/entity/wd:Q535",
            "http://link.exlibris.lunabee.ovh/entity/wd:Q535",
            "https://link.exlibris.lunabee.ovh/shelves/olivier",
            "https://link.exlibris.lunabee.ovh/entity/Q535",
            "https://link.exlibris.lunabee.ovh/entity/wd:",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q535/edit",
            "https://link.exlibris.lunabee.ovh/",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q1%7Cwd:Q2",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q1%26autocreate=true",
            "https://link.exlibris.lunabee.ovh/entity/foo:bar",
            "not a url",
        ).forEach { url -> assertNull(url, DeepLink.parse(url)) }
    }

    @Test
    fun a_reader_link_carries_the_username_as_typed() {
        mapOf(
            "https://link.exlibris.lunabee.ovh/users/OlivierB_test4" to "OlivierB_test4",
            "https://link.exlibris.lunabee.ovh/users/maxlath" to "maxlath",
            "https://link.exlibris.lunabee.ovh/users/Ana%C3%AFs" to "Anaïs",
            "https://link.exlibris.lunabee.ovh/users/ab" to "ab",
        ).forEach { (url, username) -> assertEquals(url, DeepLink.User(username), DeepLink.parse(url)) }
    }

    @Test
    fun a_group_link_carries_its_slug() {
        mapOf(
            "https://link.exlibris.lunabee.ovh/groups/le-club-de-lecture" to "le-club-de-lecture",
            "https://link.exlibris.lunabee.ovh/groups/le-club-de-lecture.2" to "le-club-de-lecture.2",
            "https://link.exlibris.lunabee.ovh/groups/lecture-%C3%A0-chamb%C3%A9ry" to "lecture-à-chambéry",
        ).forEach { (url, slug) -> assertEquals(url, DeepLink.Group(slug), DeepLink.parse(url)) }
    }

    @Test
    fun a_username_or_a_slug_outside_inventaires_rule_is_not_a_link() {
        listOf(
            "https://link.exlibris.lunabee.ovh/users/a%7Cb",
            "https://link.exlibris.lunabee.ovh/users/a%26usernames=b",
            "https://link.exlibris.lunabee.ovh/users/a",
            "https://link.exlibris.lunabee.ovh/users/abcdefghijklmnopqrstu",
            "https://link.exlibris.lunabee.ovh/users/max.lath",
            "https://link.exlibris.lunabee.ovh/users/max-lath",
            "https://link.exlibris.lunabee.ovh/users/maxlath/inventory",
            "https://link.exlibris.lunabee.ovh/users",
            "http://link.exlibris.lunabee.ovh/users/maxlath",
            "https://inventaire.io/users/maxlath",
            "https://link.exlibris.lunabee.ovh/groups/a%26b",
            "https://link.exlibris.lunabee.ovh/groups/a%7Cb",
            "https://link.exlibris.lunabee.ovh/groups/a%3Fslug=b",
            "https://link.exlibris.lunabee.ovh/groups/le%20club",
            "https://link.exlibris.lunabee.ovh/groups/le-club.",
            "https://link.exlibris.lunabee.ovh/groups/le-club/members",
            "https://link.exlibris.lunabee.ovh/groups",
            "http://link.exlibris.lunabee.ovh/groups/le-club-de-lecture",
            "https://inventaire.io/groups/le-club-de-lecture",
        ).forEach { url -> assertNull(url, DeepLink.parse(url)) }
    }

    @Test
    fun a_list_link_carries_its_id_and_the_element_it_names_if_any() {
        assertEquals(DeepLink.EntityList(LIST_ID), DeepLink.parse("https://link.exlibris.lunabee.ovh/lists/$LIST_ID"))
        assertEquals(
            DeepLink.EntityList(LIST_ID, ELEMENT_ID),
            DeepLink.parse("https://link.exlibris.lunabee.ovh/lists/$LIST_ID/element/$ELEMENT_ID"),
        )
    }

    @Test
    fun a_list_id_or_an_element_id_that_is_not_a_couchdb_id_is_not_a_link() {
        listOf(
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID%7C$LIST_ID",
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID/element/a%26b",
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID/element/$ELEMENT_ID%26ids=x",
            "https://link.exlibris.lunabee.ovh/lists/88B00676D608D9D53C5974FD9BC1009A",
            "https://link.exlibris.lunabee.ovh/lists/88b00676d608d9d53c5974fd9bc1009",
            "https://link.exlibris.lunabee.ovh/lists/${LIST_ID}0",
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID/element",
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID/elements/$ELEMENT_ID",
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID/element/$ELEMENT_ID/edit",
            "https://link.exlibris.lunabee.ovh/lists/$LIST_ID/$ELEMENT_ID",
            "https://link.exlibris.lunabee.ovh/lists",
            "https://link.exlibris.lunabee.ovh/list/$LIST_ID",
            "http://link.exlibris.lunabee.ovh/lists/$LIST_ID",
            "https://inventaire.io/lists/$LIST_ID",
        ).forEach { url -> assertNull(url, DeepLink.parse(url)) }
    }

    @Test
    fun an_element_id_opens_the_list_on_that_elements_entity() {
        val list = listWithElements("e1" to "wd:Q1", "e2" to "wd:Q2", "e3" to "wd:Q3")
        assertEquals(Destination.EntityList(LIST_ID, "wd:Q3"), DeepLink.listDestination(list, "e3"))
    }

    @Test
    fun an_element_gone_from_the_list_or_none_at_all_opens_it_on_its_first_element() {
        val list = listWithElements("e1" to "wd:Q1")
        assertEquals(Destination.EntityList(LIST_ID, null), DeepLink.listDestination(list, "gone"))
        assertEquals(Destination.EntityList(LIST_ID, null), DeepLink.listDestination(list, null))
    }

    @Test
    fun a_link_falls_back_to_the_same_page_on_inventaire() {
        assertEquals("https://inventaire.io/entity/wd:Q535", DeepLink.Entity("wd:Q535").webUrl)
        assertEquals("https://inventaire.io/users/maxlath", DeepLink.User("maxlath").webUrl)
        assertEquals("https://inventaire.io/groups/le-club-de-lecture", DeepLink.Group("le-club-de-lecture").webUrl)
        assertEquals("https://inventaire.io/lists/$LIST_ID", DeepLink.EntityList(LIST_ID).webUrl)
        assertEquals(
            "https://inventaire.io/lists/$LIST_ID/element/$ELEMENT_ID",
            DeepLink.EntityList(LIST_ID, ELEMENT_ID).webUrl,
        )
    }

    @Test
    fun a_reader_opens_their_profile_on_reseau_and_my_own_name_the_profil_sheet() {
        assertEquals(LinkTarget.Screen(AppTab.Network, Destination.User("reader")), DeepLink.userTarget("reader", "me"))
        assertEquals(LinkTarget.Screen(AppTab.Network, Destination.User("reader")), DeepLink.userTarget("reader", null))
        assertEquals(LinkTarget.Profile, DeepLink.userTarget("me", "me"))
    }

    @Test
    fun an_edition_opens_its_book_a_work_its_best_edition_a_person_their_screen() {
        assertEquals(Destination.Book(BookAnchor.Edition("inv:abc")), DeepLink.destination(entity("inv:abc", "edition")))
        assertEquals(
            Destination.Book(BookAnchor.BestEditionOfWork("wd:Q1", "Titre", null)),
            DeepLink.destination(entity("wd:Q1", "work")),
        )
        assertEquals(Destination.Author("wd:Q535"), DeepLink.destination(entity("wd:Q535", "human")))
        assertNull(DeepLink.destination(entity("wd:Q2", "serie")))
        assertNull(DeepLink.destination(entity("wd:Q3", null)))
    }

    private fun entity(uri: String, type: String?): EntityResultDto =
        EntityResultDto(uri = uri, type = type, labels = mapOf("fr" to "Titre"))

    private fun listWithElements(vararg elements: Pair<String, String>): ListWithElements = ListWithElements(
        list = EntityListEntity(id = LIST_ID, name = "Recommandés", creatorId = "lea"),
        elements = elements.map { (id, uri) -> EntityListItemEntity(id = id, listId = LIST_ID, uri = uri) },
    )

    private companion object {
        const val LIST_ID: String = "88b00676d608d9d53c5974fd9bc1009a"
        const val ELEMENT_ID: String = "88b00676d608d9d53c5974fd9bc8a871"
    }
}
