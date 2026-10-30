package studio.lunabee.nouveaurecit.data.search

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** `IsbnQueryTests`. */
class IsbnQueryTest {
    @Test
    fun a_hyphenated_isbn_13_is_recognised() {
        assertEquals("9782234096882", IsbnQuery.isbn("978-2-234-09688-2"))
        assertEquals("9782234096882", IsbnQuery.isbn("  978 2 234 09688 2 "))
    }

    @Test
    fun a_wrong_check_digit_is_a_text_query() {
        assertNull(IsbnQuery.isbn("978-2-234-09688-3"))
    }

    @Test
    fun an_isbn_10_becomes_its_isbn_13() {
        assertEquals("9782070360024", IsbnQuery.isbn("2-07-036002-4"))
        assertEquals("9780804429573", IsbnQuery.isbn("080442957x"))
    }

    @Test
    fun words_and_other_numbers_are_not_isbns() {
        assertNull(IsbnQuery.isbn("Dune 1965"))
        assertNull(IsbnQuery.isbn("1234567890123"))
        assertNull(IsbnQuery.isbn("12345"))
        assertNull(IsbnQuery.isbn(""))
    }
}
