package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `SortPileTests`: what an étagère's card draws, and — the assertion this suite exists for — **which book
 * a drag from that card carries**. If position and rank ever disagree, the user grabs a book they are not
 * looking at, silently.
 */
class SortPileTest {
    private fun book(id: String, title: String): SortBook = SortBook(id, title)

    private fun books(count: Int): List<SortBook> = (1..count).map { book("$it", "Livre $it") }

    // What is drawn

    @Test
    fun aPileDrawsAtMostFiveCovers() {
        val pile: SortPile = SortPile(books(12))

        assertEquals(5, pile.covers.size)
        assertEquals(12, pile.bookCount)
    }

    @Test
    fun aPileDrawsEveryCoverOfASmallShelf() {
        val pile: SortPile = SortPile(books(3))

        assertEquals(listOf("1", "2", "3"), pile.covers.map { it.book.id })
        assertEquals(3, pile.bookCount)
    }

    @Test
    fun oneBookIsACoverRatherThanAPile() {
        val pile: SortPile = SortPile(books(1))

        assertTrue(pile.isSingleCover)
        assertFalse(pile.isEmpty)
    }

    /** The normal state of a draft, until the first book is dropped on it: a well-formed pile of nothing. */
    @Test
    fun anEmptyEtagereDrawsNoCoverAndHandsOverNoBook() {
        val pile: SortPile = SortPile(emptyList())

        assertTrue(pile.isEmpty)
        assertTrue(pile.covers.isEmpty())
        assertNull(pile.draggableBook)
        assertEquals(0, pile.bookCount)
    }

    // The book a drag carries

    /** Front cover, first book of the section, one and the same. */
    @Test
    fun theDraggableBookIsTheFrontOfThePile() {
        val pile: SortPile = SortPile(books(5))

        assertEquals("1", pile.draggableBook?.id)
        assertEquals("1", pile.covers.first().book.id)
        assertEquals(0, pile.covers.first().depth)
    }

    @Test
    fun depthGrowsTowardsTheBackOfThePile() {
        assertEquals(listOf(0, 1, 2, 3), SortPile(books(4)).covers.map { it.depth })
    }

    /** The section is the only source of order — the pile never re-sorts. */
    @Test
    fun aPileKeepsTheOrderTheSectionGaveIt() {
        val section: SortSection = SortSection(
            id = SortSectionId.Shelf("s1"),
            name = "Romans",
            books = listOf(book("9", "Zoé"), book("4", "Alpha"), book("7", "Milieu")),
        )
        val pile: SortPile = SortPile(section)

        assertEquals(listOf("9", "4", "7"), pile.covers.map { it.book.id })
        assertEquals("9", pile.draggableBook?.id)
    }

    // Lean

    @Test
    fun everyCoverLeansWithinTenDegrees() {
        val pile: SortPile = SortPile(
            listOf(
                book("1", "Classiques français"),
                book("2", "Théâtre"),
                book("3", "Éditions rares"),
                book("4", "Science-fiction"),
                book("5", ""),
            ),
        )

        for (cover in pile.covers) {
            assertTrue(cover.tiltDegrees >= -SortPile.TILT_AMPLITUDE)
            assertTrue(cover.tiltDegrees <= SortPile.TILT_AMPLITUDE)
        }
    }

    /** Same shelf, same lean, every launch. */
    @Test
    fun aPileLeansTheSameWayEveryTime() {
        assertEquals(SortPile(books(5)).covers.map { it.tiltDegrees }, SortPile(books(5)).covers.map { it.tiltDegrees })
    }

    /** Two French titles of similar shape must not share an angle. */
    @Test
    fun similarTitlesDoNotShareOneAngle() {
        val pile: SortPile = SortPile(
            listOf(
                book("1", "Le ministère des rêves"),
                book("2", "Le ministère des rires"),
                book("3", "Le ministère des rives"),
            ),
        )

        assertEquals(3, pile.covers.map { it.tiltDegrees }.toSet().size)
    }
}
