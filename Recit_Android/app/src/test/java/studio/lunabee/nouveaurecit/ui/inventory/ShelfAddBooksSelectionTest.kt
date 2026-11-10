package studio.lunabee.nouveaurecit.ui.inventory

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.TransactionType

/** « Ajouter des livres »: which of my books show, which the search keeps, and what the button adds. */
class ShelfAddBooksSelectionTest {
    private val germinal: ItemRow = row("germinal", created = 1.0, title = "Germinal", authors = listOf("Émile Zola"))
    private val dune: ItemRow = row("dune", created = 3.0, title = "Dune", authors = listOf("Frank Herbert"))
    private val etranger: ItemRow = row("etranger", created = 2.0, title = "L'Étranger", authors = listOf("Albert Camus"))
    private val books: List<ItemRow> = listOf(germinal, dune, etranger)

    @Test
    fun onlyMyBooksNotOnTheShelfShowNewestFirst() {
        val selection: ShelfAddBooksSelection = ShelfAddBooksSelection(myBooks = books, onShelf = setOf("dune"))

        assertEquals(listOf("etranger", "germinal"), selection.visible.map { it.item.id })
    }

    @Test
    fun aTickHiddenByTheSearchIsStillCountedAndAdded() {
        val selection: ShelfAddBooksSelection = ShelfAddBooksSelection(myBooks = books, onShelf = emptySet())
            .toggling("germinal")
            .toggling("dune")
            .copy(query = "dune")

        assertEquals(listOf("dune"), selection.visible.map { it.item.id })
        assertEquals(2, selection.count)
        assertEquals(listOf("dune", "germinal"), selection.toAdd)
        assertTrue(selection.isTicked("germinal"))
    }

    @Test
    fun nothingTickedCountsZeroAndCannotAdd() {
        val selection: ShelfAddBooksSelection = ShelfAddBooksSelection(myBooks = books, onShelf = emptySet())
            .toggling("dune")
            .toggling("dune")

        assertEquals(0, selection.count)
        assertFalse(selection.canAdd)
        assertEquals(emptyList<String>(), selection.toAdd)
    }

    @Test
    fun aBookThatReachedTheShelfMeanwhileIsNoLongerAdded() {
        val selection: ShelfAddBooksSelection = ShelfAddBooksSelection(myBooks = books, onShelf = emptySet())
            .toggling("dune")
            .toggling("germinal")
            .copy(onShelf = setOf("dune"))

        assertEquals(listOf("germinal"), selection.toAdd)
    }

    @Test
    fun theSearchMatchesTitleAndAuthorWhateverTheCaseAndAccents() {
        val selection: ShelfAddBooksSelection = ShelfAddBooksSelection(myBooks = books, onShelf = emptySet())

        assertEquals(listOf("germinal"), selection.copy(query = "  emile ZOLA ").visible.map { it.item.id })
        assertEquals(listOf("etranger"), selection.copy(query = "etranger").visible.map { it.item.id })
        assertEquals(listOf("dune"), selection.copy(query = "HERB").visible.map { it.item.id })
        assertEquals(listOf("dune", "etranger", "germinal"), selection.copy(query = "  ").visible.map { it.item.id })
    }

    @Test
    fun theSearchIgnoresMyOwnUsername() {
        val selection: ShelfAddBooksSelection = ShelfAddBooksSelection(myBooks = books, onShelf = emptySet(), query = "olivier")

        assertEquals(emptyList<String>(), selection.visible.map { it.item.id })
        assertEquals(ShelfAddBooksSelection.Emptiness.NoMatch, selection.emptiness)
    }

    @Test
    fun theEmptySentenceSaysWhyNothingShows() {
        assertEquals(ShelfAddBooksSelection.Emptiness.NoBook, ShelfAddBooksSelection(myBooks = emptyList(), onShelf = emptySet()).emptiness)
        assertEquals(
            ShelfAddBooksSelection.Emptiness.AllOnShelf,
            ShelfAddBooksSelection(myBooks = books, onShelf = setOf("germinal", "dune", "etranger"), query = "zz").emptiness,
        )
        assertNull(ShelfAddBooksSelection(myBooks = books, onShelf = emptySet()).emptiness)
    }

    private fun row(id: String, created: Double, title: String, authors: List<String>): ItemRow = ItemRow(
        item = InventoryItemEntity(
            id = id,
            rev = "1",
            editionUri = "isbn:$id",
            transaction = TransactionType.Inventorying,
            visibility = emptyList(),
            ownerId = "me",
            created = created,
            searchIndex = Merges.searchIndex("olivier", authors, title, null),
        ),
        edition = EditionEntity(uri = "isbn:$id", title = title, authorNames = authors),
        owner = null,
    )
}
