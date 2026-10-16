package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `SortProjectionTests`: the one rule the sorting surface cannot get wrong — **every book sits in
 * exactly one section**. A book shown twice would be written twice; a book shown nowhere would vanish
 * on a screen whose whole promise is that nothing is lost.
 */
class SortProjectionTest {
    private fun book(id: String): SortBook = SortBook(id = id, title = "Livre $id")

    private fun shelf(id: String, name: String, bookIds: List<String>): SortSnapshot.Shelf = SortSnapshot.Shelf(id, name, bookIds)

    private fun ids(section: SortSection): List<String> = section.books.map { it.id }

    /** The invariant, asked of a whole projection: every book of the snapshot appears once, and nothing else. */
    private fun assertEveryBookAppearsExactlyOnce(projection: SortProjection, snapshot: SortSnapshot) {
        val shown: List<String> = projection.sections.flatMap { ids(it) }
        val expected: Set<String> = snapshot.books.map { it.id }.toSet()
        assertEquals(expected.size, shown.size)
        assertEquals(expected, shown.toSet())
    }

    // The library, laid out as it is filed

    @Test
    fun eachEtagereShowsTheBooksItHoldsAndTheRestFallIntoThePile() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2")), shelf("s2", "Poésie", listOf("3"))),
            books = listOf(book("1"), book("2"), book("3"), book("4")),
        )
        val projection: SortProjection = SortProjection(snapshot)

        assertEquals(listOf("Romans classiques", "Poésie", null), projection.sections.map { it.name })
        assertEquals(listOf("1", "2"), ids(projection.sections[0]))
        assertEquals(listOf("3"), ids(projection.sections[1]))
        assertEquals(listOf("4"), ids(projection.unshelved))
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun thePileComesLast() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Poésie", listOf("1"))), books = listOf(book("1"), book("2")))
        val projection: SortProjection = SortProjection(snapshot)

        assertTrue(projection.sections.last().isUnshelved)
        assertTrue(projection.sections.dropLast(1).none { it.isUnshelved })
    }

    @Test
    fun aSectionsCountIsTheNumberOfRowsUnderIt() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2", "3"))),
            books = listOf(book("1"), book("2"), book("3")),
        )
        val projection: SortProjection = SortProjection(snapshot)

        for (section in projection.sections) assertEquals(section.books.size, section.bookCount)
        assertEquals(3, projection.sections[0].bookCount)
    }

    // Every book in exactly one section, whatever the store holds

    /** A copy really can be on two étagères (ADR 0003); on this screen it is filed under the first one. */
    @Test
    fun aBookOnTwoEtageresIsShownUnderTheFirstOnly() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1")), shelf("s2", "Poésie", listOf("1"))),
            books = listOf(book("1")),
        )
        val projection: SortProjection = SortProjection(snapshot)

        assertEquals(listOf("1"), ids(projection.sections[0]))
        assertTrue(projection.sections[1].books.isEmpty())
        assertTrue(projection.unshelved.books.isEmpty())
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun anEtagereWithNoBooksStaysOnScreenEmpty() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Romans classiques", emptyList())), books = listOf(book("1")))
        val projection: SortProjection = SortProjection(snapshot)

        assertEquals(2, projection.sections.size)
        assertEquals("Romans classiques", projection.sections[0].name)
        assertTrue(projection.sections[0].books.isEmpty())
        assertEquals(listOf("1"), ids(projection.unshelved))
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun anEmptyLibraryShowsThePileAndNothingElse() {
        val snapshot: SortSnapshot = SortSnapshot.Empty
        val projection: SortProjection = SortProjection(snapshot)

        assertEquals(1, projection.sections.size)
        assertTrue(projection.sections[0].isUnshelved)
        assertTrue(projection.sections[0].books.isEmpty())
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    /** An étagère listing an item the inventory no longer holds must not conjure a row for it. */
    @Test
    fun anEtagereListingABookTheInventoryNoLongerHoldsShowsNothingForIt() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "ghost"))), books = listOf(book("1")))
        val projection: SortProjection = SortProjection(snapshot)

        assertEquals(listOf("1"), ids(projection.sections[0]))
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    // Whatever the stack

    @Test
    fun anEmptyStackShowsTheLibraryExactlyAsItIsFiled() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Romans classiques", listOf("1"))), books = listOf(book("1"), book("2")))

        assertEquals(SortProjection(snapshot), SortProjection(snapshot, emptyList()))
    }

    @Test
    fun aBookMovedOntoAnEtagereLeavesThePileForIt() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Romans classiques", emptyList())), books = listOf(book("1")))
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("1", SortSectionId.Unshelved, SortSectionId.Shelf("s1"))),
        )

        assertEquals(listOf("1"), ids(projection.sections[0]))
        assertTrue(projection.unshelved.books.isEmpty())
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun aBookMovedTwiceEndsUpInOnePlaceOnly() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1")), shelf("s2", "Poésie", emptyList())),
            books = listOf(book("1")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.MoveBook("1", SortSectionId.Shelf("s1"), SortSectionId.Unshelved),
                SortChange.MoveBook("1", SortSectionId.Unshelved, SortSectionId.Shelf("s2")),
            ),
        )

        assertTrue(projection.sections[0].books.isEmpty())
        assertEquals(listOf("1"), ids(projection.sections[1]))
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun aDraftEtagereShowsTheBooksMovedIntoIt() {
        val draftId: String = SortDraftId.make()
        val snapshot: SortSnapshot = SortSnapshot(books = listOf(book("1"), book("2")))
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.CreateShelf(draftId, "Bandes dessinées"),
                SortChange.MoveBook("2", SortSectionId.Unshelved, SortSectionId.Draft(draftId)),
            ),
        )

        assertEquals(listOf("Bandes dessinées", null), projection.sections.map { it.name })
        assertEquals(listOf("2"), ids(projection.sections[0]))
        assertEquals(listOf("1"), ids(projection.unshelved))
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    /** A stack that names a section or a book the snapshot does not know must not be able to lose a book. */
    @Test
    fun aChangeNamingSomethingUnknownLosesNoBook() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Romans classiques", listOf("1"))), books = listOf(book("1"), book("2")))
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.MoveBook("2", SortSectionId.Unshelved, SortSectionId.Shelf("gone")),
                SortChange.MoveBook("ghost", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
            ),
        )

        assertEveryBookAppearsExactlyOnce(projection, snapshot)
        assertEquals(listOf("2"), ids(projection.unshelved))
    }

    // Dragging a book from one section to another

    @Test
    fun aBookDraggedFromOneEtagereToAnotherLeavesOneAndJoinsTheOther() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2")), shelf("s2", "Poésie", listOf("3"))),
            books = listOf(book("1"), book("2"), book("3")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("2", SortSectionId.Shelf("s1"), SortSectionId.Shelf("s2"))),
        )

        assertEquals(listOf("1"), ids(projection.sections[0]))
        assertEquals(listOf("2", "3"), ids(projection.sections[1]))
        assertTrue(projection.unshelved.books.isEmpty())
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun aBookDroppedIntoThePileLeavesItsEtagere() {
        val snapshot: SortSnapshot = SortSnapshot(shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2"))), books = listOf(book("1"), book("2")))
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("1", SortSectionId.Shelf("s1"), SortSectionId.Unshelved)),
        )

        assertEquals(listOf("2"), ids(projection.sections[0]))
        assertEquals(listOf("1"), ids(projection.unshelved))
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    @Test
    fun aBookDraggedAcrossThreeSectionsEndsUpInExactlyOne() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(
                shelf("s1", "Romans classiques", listOf("1")),
                shelf("s2", "Poésie", emptyList()),
                shelf("s3", "Bandes dessinées", emptyList()),
            ),
            books = listOf(book("1")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.MoveBook("1", SortSectionId.Shelf("s1"), SortSectionId.Shelf("s2")),
                SortChange.MoveBook("1", SortSectionId.Shelf("s2"), SortSectionId.Unshelved),
                SortChange.MoveBook("1", SortSectionId.Unshelved, SortSectionId.Shelf("s3")),
            ),
        )

        assertTrue(projection.sections[0].books.isEmpty())
        assertTrue(projection.sections[1].books.isEmpty())
        assertEquals(listOf("1"), ids(projection.sections[2]))
        assertTrue(projection.unshelved.books.isEmpty())
        assertEveryBookAppearsExactlyOnce(projection, snapshot)
    }

    /** A book put back where it came from records nothing, so the screen does not claim there is work to discard. */
    @Test
    fun aBookDroppedBackOnTheSectionItCameFromRecordsNothing() {
        assertNull(SortChange.move("1", SortSectionId.Shelf("s1"), SortSectionId.Shelf("s1")))
        assertNull(SortChange.move("1", SortSectionId.Unshelved, SortSectionId.Unshelved))
        assertEquals(
            SortChange.MoveBook("1", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
            SortChange.move("1", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
        )
    }

    // The counts, and what discarding restores

    @Test
    fun theCountInAHeaderFollowsTheMoves() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2")), shelf("s2", "Poésie", emptyList())),
            books = listOf(book("1"), book("2"), book("3")),
        )
        assertEquals(listOf(2, 0, 1), SortProjection(snapshot).sections.map { it.bookCount })

        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.MoveBook("1", SortSectionId.Shelf("s1"), SortSectionId.Shelf("s2")),
                SortChange.MoveBook("3", SortSectionId.Unshelved, SortSectionId.Shelf("s2")),
            ),
        )
        assertEquals(listOf(1, 2, 0), projection.sections.map { it.bookCount })
    }

    /** « Annuler » throws the stack away, and the screen has to come back to exactly the library it opened on. */
    @Test
    fun discardingTheStackRestoresTheSnapshotExactly() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2")), shelf("s2", "Poésie", listOf("3"))),
            books = listOf(book("1"), book("2"), book("3"), book("4")),
        )
        val changes: List<SortChange> = listOf(
            SortChange.CreateShelf(SortDraftId.make(), "Bandes dessinées"),
            SortChange.MoveBook("1", SortSectionId.Shelf("s1"), SortSectionId.Shelf("s2")),
            SortChange.MoveBook("4", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
        )

        assertNotEquals(SortProjection(snapshot), SortProjection(snapshot, changes))
        assertEquals(SortProjection(snapshot), SortProjection(snapshot, emptyList()))
    }

    // The invariant, over every stack dragging can build

    @Test
    fun everyBookSitsInExactlyOneSectionWhateverTheStack() {
        val s1: SortSectionId = SortSectionId.Shelf("s1")
        val s2: SortSectionId = SortSectionId.Shelf("s2")
        val pile: SortSectionId = SortSectionId.Unshelved
        val stacks: List<List<SortChange>> = listOf(
            emptyList(),
            listOf(SortChange.MoveBook("1", s1, s2)),
            listOf(SortChange.MoveBook("1", s1, pile), SortChange.MoveBook("3", pile, s1)),
            listOf(SortChange.MoveBook("2", s1, s2), SortChange.MoveBook("2", s2, pile), SortChange.MoveBook("2", pile, s1)),
            listOf(SortChange.MoveBook("1", s1, pile), SortChange.MoveBook("2", s1, pile), SortChange.MoveBook("3", pile, s2)),
        )
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans classiques", listOf("1", "2")), shelf("s2", "Poésie", emptyList())),
            books = listOf(book("1"), book("2"), book("3")),
        )

        for (changes in stacks) {
            val projection: SortProjection = SortProjection(snapshot, changes)
            assertEveryBookAppearsExactlyOnce(projection, snapshot)
            assertEquals(snapshot.books.size, projection.sections.sumOf { it.bookCount })
        }
    }

    @Test
    fun aDraftIdIsNeverMistakenForAServerDocument() {
        assertTrue(SortDraftId.isDraft(SortDraftId.make()))
        assertFalse(SortDraftId.isDraft("d3fbdd9e0a8d2b1c"))
    }

    // Arrival order

    /** A book dropped on an étagère goes to the **front** of it: the front of a pile is what a drag carries. */
    @Test
    fun aBookDroppedOnAnEtagereLandsAtTheFrontOfIt() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", listOf("1", "2"))),
            books = listOf(SortBook("1", "A"), SortBook("2", "B"), SortBook("3", "C")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("3", SortSectionId.Unshelved, SortSectionId.Shelf("s1"))),
        )

        assertEquals(listOf("3", "1", "2"), ids(projection.sections.first()))
    }

    /** Two books filed into the same étagère read newest first. */
    @Test
    fun theMostRecentlyFiledBookIsInFront() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", listOf("1"))),
            books = listOf(SortBook("1", "A"), SortBook("2", "B"), SortBook("3", "C")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.MoveBook("2", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
                SortChange.MoveBook("3", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
            ),
        )

        assertEquals(listOf("3", "2", "1"), ids(projection.sections.first()))
    }

    /** A book moved several times counts as arriving where it finally sits. */
    @Test
    fun onlyTheLastMoveDecidesWhereABookSits() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", emptyList()), shelf("s2", "Poésie", emptyList())),
            books = listOf(SortBook("1", "A"), SortBook("2", "B")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(
                SortChange.MoveBook("1", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
                SortChange.MoveBook("2", SortSectionId.Unshelved, SortSectionId.Shelf("s1")),
                SortChange.MoveBook("1", SortSectionId.Shelf("s1"), SortSectionId.Shelf("s2")),
            ),
        )

        assertEquals(listOf("2"), ids(projection.sections[0]))
        assertEquals(listOf("1"), ids(projection.sections[1]))
    }

    @Test
    fun untouchedBooksKeepSnapshotOrder() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", listOf("1", "2", "3"))),
            books = listOf(SortBook("1", "A"), SortBook("2", "B"), SortBook("3", "C")),
        )

        assertEquals(listOf("1", "2", "3"), ids(SortProjection(snapshot).sections.first()))
    }

    /** A book taken off an étagère comes back to the front of « à ranger », where the user's eye already is. */
    @Test
    fun aBookTakenOffAnEtagereReturnsToTheFrontOfThePile() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", listOf("3"))),
            books = listOf(SortBook("1", "A"), SortBook("2", "B"), SortBook("3", "C")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("3", SortSectionId.Shelf("s1"), SortSectionId.Unshelved)),
        )

        assertEquals(listOf("3", "1", "2"), ids(projection.unshelved))
    }

    @Test
    fun aBookMovedOntoAnEtagereJoinsIt() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", listOf("1", "2"))),
            books = listOf(SortBook("1", "A"), SortBook("2", "B"), SortBook("3", "C")),
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("3", SortSectionId.Unshelved, SortSectionId.Shelf("s1"))),
        )

        assertEquals(setOf("1", "2", "3"), ids(projection.sections.first()).toSet())
    }

    /** A book nobody has touched keeps its snapshot position, whatever moved elsewhere. */
    @Test
    fun anUntouchedEtagereKeepsItsOrder() {
        val snapshot: SortSnapshot = SortSnapshot(
            shelves = listOf(shelf("s1", "Romans", listOf("1", "2", "3")), shelf("s2", "Poésie", listOf("4"))),
            books = (1..4).map { SortBook("$it", "T$it") },
        )
        val projection: SortProjection = SortProjection(
            snapshot,
            listOf(SortChange.MoveBook("4", SortSectionId.Shelf("s2"), SortSectionId.Unshelved)),
        )

        assertEquals(listOf("1", "2", "3"), ids(projection.sections.first()))
    }
}
