package studio.lunabee.nouveaurecit.ui.common

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WebLinksTest {
    @Test
    fun full_addresses_and_www_ones_are_found_without_the_closing_punctuation() {
        val text: String = "Voir https://inventaire.io/lists/abc. Et www.utopitheque.com, puis rien."
        val links: List<Pair<IntRange, String>> = WebLinks.find(text)
        assertEquals(listOf("https://inventaire.io/lists/abc", "https://www.utopitheque.com"), links.map { it.second })
        assertEquals(listOf("https://inventaire.io/lists/abc", "www.utopitheque.com"), links.map { text.substring(it.first) })
    }

    @Test
    fun a_text_without_address_has_no_link() {
        assertTrue(WebLinks.find("Des polars, rien que des polars.").isEmpty())
    }
}
