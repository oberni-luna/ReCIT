package studio.lunabee.nouveaurecit.designsystem

import org.junit.Assert.assertEquals
import org.junit.Test

class InitialsTest {
    @Test
    fun two_words_give_their_first_letters() {
        assertEquals("VH", initialsOf("Victor Hugo"))
        assertEquals("JD", initialsOf("jean-dupont"))
    }

    @Test
    fun one_word_gives_its_first_two_letters() {
        assertEquals("OL", initialsOf("OlivierB"))
        assertEquals("SK", initialsOf("Skadi_"))
    }

    @Test
    fun nothing_gives_nothing() {
        assertEquals("", initialsOf("  "))
    }
}
