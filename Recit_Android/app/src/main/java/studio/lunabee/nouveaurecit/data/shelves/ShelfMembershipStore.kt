package studio.lunabee.nouveaurecit.data.shelves

import androidx.room.withTransaction
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.db.ShelfDao
import studio.lunabee.nouveaurecit.data.db.ShelfItemCrossRef

/** Which books stand on which étagère, in the store: what [ShelfMembership] reads and writes. */
interface ShelfMembershipStore {
    suspend fun itemIds(shelfId: String): List<String>

    suspend fun link(shelfId: String, itemIds: List<String>)

    suspend fun unlink(shelfId: String, itemIds: List<String>)

    suspend fun hasShelf(shelfId: String): Boolean

    suspend fun hasItem(itemId: String): Boolean

    /** The étagère's books become [serverItemIds], less those the store does not hold; nothing when the étagère has gone. */
    suspend fun replaceItems(shelfId: String, serverItemIds: List<String>)
}

/** The membership in Room's `shelf_items`. */
class RoomShelfMembershipStore(private val db: AppDatabase) : ShelfMembershipStore {
    private val dao: ShelfDao = db.shelfDao()

    override suspend fun itemIds(shelfId: String): List<String> = dao.itemIds(shelfId)

    override suspend fun link(shelfId: String, itemIds: List<String>) = dao.link(itemIds.map { ShelfItemCrossRef(shelfId, it) })

    override suspend fun unlink(shelfId: String, itemIds: List<String>) = db.withTransaction {
        itemIds.forEach { dao.unlink(shelfId, it) }
    }

    override suspend fun hasShelf(shelfId: String): Boolean = dao.get(shelfId) != null

    override suspend fun hasItem(itemId: String): Boolean = db.inventoryDao().get(itemId) != null

    override suspend fun replaceItems(shelfId: String, serverItemIds: List<String>) {
        val known: Set<String> = db.inventoryDao().get(serverItemIds).map { it.id }.toSet()
        if (dao.get(shelfId) != null) dao.replaceItems(shelfId, serverItemIds.filter { it in known })
    }
}
