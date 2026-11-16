package studio.lunabee.nouveaurecit.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto

class DeepLinkTest {
    @Test
    fun an_entity_link_carries_its_uri_whatever_its_prefix() {
        assertEquals("isbn:9782070360024", DeepLink.entityUri("https://link.exlibris.lunabee.ovh/entity/isbn:9782070360024"))
        assertEquals("wd:Q535", DeepLink.entityUri("https://link.exlibris.lunabee.ovh/entity/wd:Q535"))
    }

    @Test
    fun another_host_another_path_or_a_uri_without_a_prefix_is_not_a_link() {
        listOf(
            "https://inventaire.io/entity/wd:Q535",
            "http://link.exlibris.lunabee.ovh/entity/wd:Q535",
            "https://link.exlibris.lunabee.ovh/users/olivier",
            "https://link.exlibris.lunabee.ovh/entity/Q535",
            "https://link.exlibris.lunabee.ovh/entity/wd:",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q535/edit",
            "https://link.exlibris.lunabee.ovh/",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q1%7Cwd:Q2",
            "https://link.exlibris.lunabee.ovh/entity/wd:Q1%26autocreate=true",
            "https://link.exlibris.lunabee.ovh/entity/foo:bar",
            "not a url",
        ).forEach { url -> assertNull(url, DeepLink.entityUri(url)) }
    }

    @Test
    fun a_link_falls_back_to_the_same_page_on_inventaire() {
        assertEquals("https://inventaire.io/entity/wd:Q535", DeepLink.webUrl("wd:Q535"))
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
}
