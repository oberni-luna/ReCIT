package studio.lunabee.nouveaurecit.data.book

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.book.EditionLanguageFilter.All
import studio.lunabee.nouveaurecit.data.book.EditionLanguageFilter.Code
import studio.lunabee.nouveaurecit.data.book.EditionLanguageFilter.Option
import studio.lunabee.nouveaurecit.data.book.EditionLanguageFilter.Unspecified
import java.util.Locale

/** `EditionLanguageFilterTests`. */
class EditionLanguageFilterTest {
    @Test
    fun the_menu_counts_every_edition_then_each_language_then_the_unspecified() {
        val options: List<Option> = EditionLanguageFilter.options(listOf("en", "fr", "EN", null, "", "de", "fr", "en"))
        assertEquals(
            listOf(Option(All, 8), Option(Code("en"), 3), Option(Code("fr"), 2), Option(Code("de"), 1), Option(Unspecified, 2)),
            options,
        )
    }

    @Test
    fun no_unspecified_entry_when_every_edition_has_a_language() {
        assertEquals(listOf(Option(All, 2), Option(Code("fr"), 2)), EditionLanguageFilter.options(listOf("fr", "fr")))
    }

    @Test
    fun the_phone_language_is_the_default_only_when_the_work_has_editions_in_it() {
        val options: List<Option> = EditionLanguageFilter.options(listOf("en", "fr"))
        assertEquals(Code("fr"), EditionLanguageFilter.preferred("fr", options))
        assertEquals(All, EditionLanguageFilter.preferred("ja", options))
        assertEquals(All, EditionLanguageFilter.preferred(null, options))
    }

    @Test
    fun the_filter_admits_its_editions() {
        assertTrue(Code("fr").admits(" FR "))
        assertFalse(Code("fr").admits("en"))
        assertTrue(Unspecified.admits(null))
        assertTrue(Unspecified.admits(" "))
        assertFalse(Unspecified.admits("fr"))
        assertTrue(All.admits(null))
    }

    @Test
    fun a_language_is_named_in_the_phone_language_capitalised() {
        assertEquals("Anglais", EditionLanguageFilter.name("en", Locale.FRENCH))
        assertEquals("French", EditionLanguageFilter.name("fr", Locale.ENGLISH))
    }
}
