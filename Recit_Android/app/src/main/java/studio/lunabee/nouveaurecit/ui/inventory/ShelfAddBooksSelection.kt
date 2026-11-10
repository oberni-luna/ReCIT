package studio.lunabee.nouveaurecit.ui.inventory

import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.model.Merges

/**
 * What `ShelfAddBooksSheet` (iOS feature 0089) shows and adds, apart from Compose: my books not on the
 * étagère yet, newest first; those the search keeps; and the ticked ones the button adds.
 *
 * The search matches the edition's title and displayed author names, case and accents aside — not the
 * copy's `searchIndex`, which also holds my own username and would match every book. It hides books, it
 * does not untick them: a book ticked then filtered out is still counted, and still added.
 */
data class ShelfAddBooksSelection(
    val myBooks: List<ItemRow>,
    val onShelf: Set<String>,
    val ticked: Set<String> = emptySet(),
    val query: String = "",
) {
    /** Which sentence stands in for the rows, when no row shows. */
    enum class Emptiness { NoBook, AllOnShelf, NoMatch }

    val candidates: List<ItemRow> = myBooks.filter { it.item.id !in onShelf }.sortedByDescending { it.item.created }

    val trimmedQuery: String = query.trim()

    val visible: List<ItemRow> = Merges.fold(trimmedQuery).let { folded ->
        if (folded.isEmpty()) candidates else candidates.filter { matches(it, folded) }
    }

    /** The ticked books still to add, newest first: one that reached the étagère meanwhile drops out. */
    val toAdd: List<String> = candidates.filter { it.item.id in ticked }.map { it.item.id }

    val count: Int get() = toAdd.size

    val canAdd: Boolean get() = toAdd.isNotEmpty()

    val emptiness: Emptiness?
        get() = when {
            myBooks.isEmpty() -> Emptiness.NoBook
            candidates.isEmpty() -> Emptiness.AllOnShelf
            visible.isEmpty() -> Emptiness.NoMatch
            else -> null
        }

    fun isTicked(itemId: String): Boolean = itemId in ticked

    fun toggling(itemId: String): ShelfAddBooksSelection = copy(ticked = if (itemId in ticked) ticked - itemId else ticked + itemId)

    private fun matches(row: ItemRow, foldedQuery: String): Boolean =
        (listOf(row.title) + row.authorNames).any { Merges.fold(it).contains(foldedQuery) }
}
