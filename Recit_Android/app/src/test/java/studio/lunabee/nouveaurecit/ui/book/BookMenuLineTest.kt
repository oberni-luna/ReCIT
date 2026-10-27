package studio.lunabee.nouveaurecit.ui.book

import org.junit.Assert.assertEquals
import org.junit.Test

/** The book's « … » menu, before it is worded: which lines, in which order, on each side of the ownership line. */
class BookMenuLineTest {
    private val shelves: List<MembershipEntry> = listOf(MembershipEntry("s1", "Salon", isMember = true), MembershipEntry("s2", "Chambre", isMember = false))
    private val lists: List<MembershipEntry> = listOf(MembershipEntry("l1", "À lire", isMember = false))

    @Test
    fun myCopyOfASingleWorkEditionFilesListsAndRemoves() {
        val lines: List<BookMenuLine> = BookMenuLine.of(ownsCopy = true, shelves = shelves, lists = lists, singleWorkUri = "wd:Q1")
        assertEquals(listOf(BookMenuLine.Shelves(shelves), BookMenuLine.Lists(lists), BookMenuLine.Remove), lines)
    }

    @Test
    fun myCopyBehindSeveralWorksHasNoListLine() {
        val lines: List<BookMenuLine> = BookMenuLine.of(ownsCopy = true, shelves = shelves, lists = emptyList(), singleWorkUri = null)
        assertEquals(listOf(BookMenuLine.Shelves(shelves), BookMenuLine.Remove), lines)
    }

    @Test
    fun myCopyWithoutShelvesStillOffersTheShelfLineForItsCreation() {
        val lines: List<BookMenuLine> = BookMenuLine.of(ownsCopy = true, shelves = emptyList(), lists = emptyList(), singleWorkUri = "wd:Q1")
        assertEquals(listOf(BookMenuLine.Shelves(emptyList()), BookMenuLine.Lists(emptyList()), BookMenuLine.Remove), lines)
    }

    @Test
    fun someoneElsesCopyListsAndAddsToMyBooks() {
        val lines: List<BookMenuLine> = BookMenuLine.of(ownsCopy = false, shelves = emptyList(), lists = lists, singleWorkUri = "wd:Q1")
        assertEquals(listOf(BookMenuLine.Lists(lists), BookMenuLine.AddToInventory), lines)
    }

    @Test
    fun someoneElsesCopyBehindSeveralWorksOnlyAdds() {
        val lines: List<BookMenuLine> = BookMenuLine.of(ownsCopy = false, shelves = emptyList(), lists = emptyList(), singleWorkUri = null)
        assertEquals(listOf(BookMenuLine.AddToInventory), lines)
    }

    @Test
    fun stateDecidesOwnershipFromMyItem() {
        val mine = BookActionsState(editionUri = "isbn:1", myItemId = "item", myShelves = shelves, myLists = lists, singleWorkUri = "wd:Q1")
        val theirs: BookActionsState = mine.copy(myItemId = null)
        assertEquals(BookMenuLine.Remove, mine.lines.last())
        assertEquals(BookMenuLine.AddToInventory, theirs.lines.last())
    }
}
