package studio.lunabee.nouveaurecit.ui.inventory

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility

/** The Inventaire tab's pure parts: which copies stand on a shelf, its card's geometry, the first-sync banner, a shelf's visibility. */
class ShelfLogicTest {
    @Test
    fun drawnBooksPutCoversFirstThenNewest() {
        val rows = listOf(
            row("noCoverNew", "me", 30.0, image = null),
            row("coverOld", "me", 1.0, image = "https://x/1.jpg"),
            row("coverNew", "me", 20.0, image = "https://x/2.jpg"),
        )
        assertEquals(listOf("coverNew", "coverOld", "noCoverNew"), ShelfDrawnBooks.from(rows).map { it.item.id })
        assertEquals(listOf("coverNew"), ShelfDrawnBooks.from(rows, limit = 1).map { it.item.id })
    }

    @Test
    fun cardMetricsFollowTheIosProportions() {
        val metrics = ShelfCardMetrics(width = 320f)
        assertEquals(180f, metrics.zoneHeight, 0.001f)
        assertEquals(45f, metrics.topRoom, 0.001f)
        assertEquals(320f * 129f / 820f, metrics.plankHeight, 0.001f)
        assertEquals(272f, metrics.booksWidth, 0.001f)
        // 180 × 0.5 = 90 tall, 60 wide: four fit in 272 with a 4 gap, five do not.
        assertEquals(4, metrics.fittingCount)
        assertEquals(0, ShelfCardMetrics(width = 0f).fittingCount)
    }

    @Test
    fun firstSyncStateFollowsLastSyncThenProgress() {
        assertEquals(FirstSyncState.Synced, FirstSyncState.from(lastInventorySync = 1.0, progress = SyncStatus.Progress()))
        assertEquals(FirstSyncState.Waiting, FirstSyncState.from(lastInventorySync = null, progress = null))
        val running: FirstSyncState = FirstSyncState.from(null, SyncStatus.Progress(received = 1, announced = 4))
        assertEquals(0.25f, running.fraction)
        assertEquals(25, running.percent)
        assertEquals(null, FirstSyncState.from(null, SyncStatus.Progress()).percent)
    }

    @Test
    fun shelfVisibilityRoundTrips() {
        assertEquals(ShelfVisibility.Private, ShelfVisibility.from(emptyList()))
        assertEquals(ShelfVisibility.Friends, ShelfVisibility.from(listOf(Visibility.Friends)))
        assertEquals(ShelfVisibility.Public, ShelfVisibility.from(listOf(Visibility.Friends, Visibility.Public)))
        assertEquals(ShelfVisibility.Private, ShelfVisibility.from(listOf(Visibility.Groups)))
        ShelfVisibility.entries.forEach { assertEquals(it, ShelfVisibility.from(it.raw)) }
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
