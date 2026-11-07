package studio.lunabee.exlibris.backend.items

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.exists
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.not
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import studio.lunabee.exlibris.backend.db.ItemShelvesTable
import studio.lunabee.exlibris.backend.db.ItemsTable
import studio.lunabee.exlibris.backend.db.ShelvesTable
import studio.lunabee.exlibris.backend.db.SnapshotWorksTable
import studio.lunabee.exlibris.backend.db.Visibility

/** `inventory-view`'s reads, in SQL over the books and their stored snapshots: never a call to inventaire.io. */
class InventoryViewRepository(
    private val database: Database,
) {
    /** The books of [scope] [viewerId] may see, the newest first. */
    suspend fun items(
        scope: InventoryScope,
        viewerId: String?,
    ): List<ViewItem> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ItemsTable
                    .select(ItemsTable.id, ItemsTable.owner, ItemsTable.entity)
                    .where { condition(scope, viewerId) }
                    .orderBy(ItemsTable.created to SortOrder.DESC, ItemsTable.id to SortOrder.ASC)
                    .map {
                        ViewItem(
                            id = it[ItemsTable.id],
                            owner = it[ItemsTable.owner],
                            entity = it[ItemsTable.entity],
                        )
                    }
            }
        }

    /** The works of each of [entities]' snapshots, in their order. */
    suspend fun works(entities: Collection<String>): Map<String, List<SnapshotWork>> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                SnapshotWorksTable
                    .selectAll()
                    .where { SnapshotWorksTable.uri inList entities.distinct() }
                    .orderBy(SnapshotWorksTable.uri to SortOrder.ASC, SnapshotWorksTable.position to SortOrder.ASC)
                    .groupBy(
                        { it[SnapshotWorksTable.uri] },
                        {
                            SnapshotWork(
                                uri = it[SnapshotWorksTable.workUri],
                                authors = it[SnapshotWorksTable.authors],
                                genres = it[SnapshotWorksTable.genres],
                                subjects = it[SnapshotWorksTable.subjects],
                            )
                        },
                    )
            }
        }

    suspend fun shelfExists(shelfId: String): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                !ShelvesTable
                    .selectAll()
                    .where { ShelvesTable.id eq shelfId }
                    .empty()
            }
        }

    private fun condition(
        scope: InventoryScope,
        viewerId: String?,
    ): Op<Boolean> {
        val visible: Op<Boolean> = Visibility.visibleTo(viewerId, ItemsTable.owner, ItemsTable.visibility)
        return when (scope) {
            is InventoryScope.Owner -> {
                val owned: Op<Boolean> = (ItemsTable.owner eq scope.userId) and visible
                if (scope.withoutShelf) owned and not(onShelf(null)) else owned
            }

            is InventoryScope.OnShelf -> {
                onShelf(scope.shelfId) and visible
            }

            is InventoryScope.Group -> {
                (ItemsTable.owner inList scope.memberIds) and Visibility.holdsAnyOf(ItemsTable.visibility, scope.keys)
            }
        }
    }

    /** The book is on [shelfId], or on any étagère when it is `null`. */
    private fun onShelf(shelfId: String?): Op<Boolean> =
        exists(
            ItemShelvesTable.select(ItemShelvesTable.shelfId).where {
                val ofItem: Op<Boolean> = ItemShelvesTable.itemId eq ItemsTable.id
                shelfId?.let { ofItem and (ItemShelvesTable.shelfId eq it) } ?: ofItem
            },
        )
}
