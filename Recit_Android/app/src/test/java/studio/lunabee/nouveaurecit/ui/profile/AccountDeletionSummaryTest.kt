package studio.lunabee.nouveaurecit.ui.profile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.ui.profile.AccountDeletionSummary.Kind
import studio.lunabee.nouveaurecit.ui.profile.AccountDeletionSummary.Line

class AccountDeletionSummaryTest {
    @Test
    fun every_count_draws_a_line_in_reading_order() {
        val summary = AccountDeletionSummary(books = 12, shelves = 3, lists = 1)
        assertEquals(listOf(Line(Kind.Books, 12), Line(Kind.Shelves, 3), Line(Kind.Lists, 1)), summary.lines)
        assertFalse(summary.isEmpty)
    }

    @Test
    fun zeroes_are_dropped_rather_than_drawn() {
        val summary = AccountDeletionSummary(books = 0, shelves = 2, lists = 0)
        assertEquals(listOf(Line(Kind.Shelves, 2)), summary.lines)
    }

    @Test
    fun an_account_with_nothing_is_empty() {
        val summary = AccountDeletionSummary(books = 0, shelves = 0, lists = 0)
        assertTrue(summary.lines.isEmpty())
        assertTrue(summary.isEmpty)
    }

    @Test
    fun a_single_book_is_enough_not_to_be_empty() {
        assertFalse(AccountDeletionSummary(books = 1, shelves = 0, lists = 0).isEmpty)
    }
}
