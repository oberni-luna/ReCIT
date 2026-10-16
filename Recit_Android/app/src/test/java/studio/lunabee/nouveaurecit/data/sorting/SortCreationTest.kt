package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `SortCreationTests` (`SortChange.creation`): creating an étagère by dropping a book onto the grid's
 * « + » tile — one gesture, two changes. A move naming a draft nobody created is ignored by the
 * projection, so the book would sit where it was while the screen said otherwise.
 */
class SortCreationTest {
    @Test
    fun namingAnEtagereWithoutABookIsOneChange() {
        assertEquals(listOf(SortChange.CreateShelf("draft:1", "Poésie")), SortChange.creation("draft:1", "Poésie"))
    }

    @Test
    fun droppingABookOntoTheTileCreatesAndFiles() {
        val changes: List<SortChange> = SortChange.creation("draft:1", "Poésie", filling = "book-1", from = SortSectionId.Unshelved)

        assertEquals(
            listOf(
                SortChange.CreateShelf("draft:1", "Poésie"),
                SortChange.MoveBook("book-1", SortSectionId.Unshelved, SortSectionId.Draft("draft:1")),
            ),
            changes,
        )
    }

    /** The creation comes first, so the projection knows the section by the time the move names it. */
    @Test
    fun theCreationPrecedesTheMove() {
        val changes: List<SortChange> = SortChange.creation("draft:1", "Poésie", filling = "book-1", from = SortSectionId.Shelf("s1"))

        assertTrue("the creation must come first, got ${changes.firstOrNull()}", changes.first() is SortChange.CreateShelf)
    }

    /** A book the projection does not know cannot be filed — but the étagère is still created. */
    @Test
    fun anUnknownBookStillLeavesTheEtagereCreated() {
        val changes: List<SortChange> = SortChange.creation("draft:1", "Poésie", filling = "book-1", from = null)

        assertEquals(listOf(SortChange.CreateShelf("draft:1", "Poésie")), changes)
    }

    /** A move to where the book already is records nothing. */
    @Test
    fun aBookAlreadyInTheDraftRecordsNoMove() {
        val changes: List<SortChange> = SortChange.creation("draft:1", "Poésie", filling = "book-1", from = SortSectionId.Draft("draft:1"))

        assertEquals(1, changes.size)
    }
}
