package studio.lunabee.nouveaurecit.ui.profile

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.ui.profile.BoldMarkup.Run

class BoldMarkupTest {
    @Test
    fun the_starred_part_is_bold_and_the_rest_is_not() {
        assertEquals(
            listOf(Run("Ex-libris range vos livres sur ", false), Run("inventaire.io", true), Run(", une bibliothèque.", false)),
            BoldMarkup.parse("Ex-libris range vos livres sur **inventaire.io**, une bibliothèque."),
        )
    }

    @Test
    fun plain_text_is_one_run() {
        assertEquals(listOf(Run("Rien de gras.", false)), BoldMarkup.parse("Rien de gras."))
    }

    @Test
    fun an_unclosed_marker_stays_literal() {
        assertEquals(listOf(Run("Un **oubli", false)), BoldMarkup.parse("Un **oubli"))
    }

    @Test
    fun several_bold_parts_and_a_bold_start() {
        assertEquals(
            listOf(Run("A", true), Run(" et ", false), Run("B", true)),
            BoldMarkup.parse("**A** et **B**"),
        )
    }

    @Test
    fun empty_markers_draw_nothing() {
        assertEquals(listOf(Run("a", false), Run("b", false)), BoldMarkup.parse("a****b"))
    }
}
