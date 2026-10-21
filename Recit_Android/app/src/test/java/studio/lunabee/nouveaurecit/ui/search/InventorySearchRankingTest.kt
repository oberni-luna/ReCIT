package studio.lunabee.nouveaurecit.ui.search

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.TransactionType

class InventorySearchRankingTest {
    private fun candidate(id: String, index: String, isMine: Boolean, created: Double) =
        InventorySearchRanking.Candidate(id, Merges.fold(index), isMine, created)

    @Test
    fun emptyQueryMatchesNothing() {
        val outcome = InventorySearchRanking.rank(listOf(candidate("a", "Zola", true, 1.0)), "  ")
        assertEquals(InventorySearchRanking.Outcome.None, outcome)
    }

    @Test
    fun matchingFoldsCaseAndAccents() {
        val outcome = InventorySearchRanking.rank(listOf(candidate("a", "Émile Zola Germinal", true, 1.0)), "EMILE zola")
        assertEquals(listOf("a"), outcome.matches.map { it.id })
    }

    @Test
    fun mineFirstThenNewestAndCappedWithTotal() {
        val candidates = listOf(
            candidate("friendNew", "zola", isMine = false, created = 50.0),
            candidate("mineOld", "zola", isMine = true, created = 1.0),
            candidate("mineNew", "zola", isMine = true, created = 10.0),
            candidate("friendOld", "zola", isMine = false, created = 5.0),
            candidate("other", "hugo", isMine = true, created = 99.0),
        )
        val outcome = InventorySearchRanking.rank(candidates, "zola")
        assertEquals(listOf("mineNew", "mineOld", "friendNew"), outcome.matches.map { it.id })
        assertEquals(4, outcome.totalCount)
        val all = InventorySearchRanking.rank(candidates, "zola", InventorySearchRanking.NO_LIMIT)
        assertEquals(listOf("mineNew", "mineOld", "friendNew", "friendOld"), all.matches.map { it.id })
    }

    @Test
    fun rankItemsUsesTheOwnerToDecideWhatIsMine() {
        val rows = listOf(row("x", owner = "friend", created = 9.0), row("y", owner = "me", created = 1.0))
        val outcome = InventorySearchRanking.rankItems(rows, "germinal", ownerId = "me")
        assertEquals(listOf("y", "x"), outcome.items.map { it.item.id })
        assertEquals(2, outcome.totalCount)
    }

    private fun row(id: String, owner: String, created: Double, image: String? = null): ItemRow = ItemRow(
        item = InventoryItemEntity(
            id = id,
            rev = "1",
            editionUri = "isbn:$id",
            transaction = TransactionType.Inventorying,
            visibility = emptyList(),
            ownerId = owner,
            created = created,
            searchIndex = Merges.searchIndex(owner, listOf("Émile Zola"), "Germinal", null),
        ),
        edition = EditionEntity(uri = "isbn:$id", title = "Germinal", image = image),
        owner = null,
    )
}
