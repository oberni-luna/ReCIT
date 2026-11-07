package studio.lunabee.exlibris.backend.shelves

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.JoinType
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.exceptions.ExposedSQLException
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.batchInsert
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.db.ItemShelvesTable
import studio.lunabee.exlibris.backend.db.ItemsTable
import studio.lunabee.exlibris.backend.db.ShelvesTable
import studio.lunabee.exlibris.backend.db.Visibility

class ShelvesRepository(
    private val database: Database,
) {
    /** `false` when the owner's account is gone: the foreign key said no. */
    suspend fun insert(shelf: ShelfRecord): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) {
                    ShelvesTable.insert {
                        it[id] = shelf.id
                        it[version] = shelf.version
                        it[owner] = shelf.owner
                        it[name] = shelf.name
                        it[description] = shelf.description
                        it[visibility] = shelf.visibility
                        it[color] = shelf.color
                        it[created] = shelf.created
                    }
                }
                true
            } catch (error: ExposedSQLException) {
                if (error.sqlState != FOREIGN_KEY_VIOLATION) throw error
                logger.info("An étagère was refused a missing owner: {}", error.message)
                false
            }
        }

    /** The étagères of [ids] that exist, whoever may see them. */
    suspend fun find(ids: Collection<String>): List<ShelfRecord> = records { ShelvesTable.id inList ids }

    /** Those of [ids] [viewerId] may see. */
    suspend fun visible(
        ids: Collection<String>,
        viewerId: String?,
    ): List<ShelfRecord> =
        records {
            (ShelvesTable.id inList ids) and Visibility.visibleTo(viewerId, ShelvesTable.owner, ShelvesTable.visibility)
        }

    /** [owners]' étagères [viewerId] may see. */
    suspend fun visibleOf(
        owners: Collection<String>,
        viewerId: String?,
    ): List<ShelfRecord> =
        records {
            (ShelvesTable.owner inList owners) and
                Visibility.visibleTo(viewerId, ShelvesTable.owner, ShelvesTable.visibility)
        }

    /** Writes [fields] and moves the étagère's revision and `updated`. */
    suspend fun update(
        shelfId: String,
        fields: ShelfFields,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                ShelvesTable.update({ ShelvesTable.id eq shelfId }) {
                    it[version] = version + 1
                    it[name] = fields.name
                    it[description] = fields.description
                    it[visibility] = fields.visibility
                    it[color] = fields.color
                    it[updated] = now
                }
            }
        }
    }

    /**
     * The ids of the books on each of [shelfIds] that [viewerId] may see, by the books' own visibility
     * (`getAuthorizedItemsByShelves`), in the order they were filed.
     */
    suspend fun itemIds(
        shelfIds: Collection<String>,
        viewerId: String?,
    ): Map<String, List<String>> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ItemShelvesTable
                    .join(ItemsTable, JoinType.INNER, ItemShelvesTable.itemId, ItemsTable.id)
                    .select(ItemShelvesTable.shelfId, ItemShelvesTable.itemId)
                    .where {
                        (ItemShelvesTable.shelfId inList shelfIds) and
                            Visibility.visibleTo(viewerId, ItemsTable.owner, ItemsTable.visibility)
                    }.orderBy(ItemShelvesTable.added to SortOrder.ASC, ItemShelvesTable.itemId to SortOrder.ASC)
                    .groupBy({ it[ItemShelvesTable.shelfId] }, { it[ItemShelvesTable.itemId] })
            }
        }

    /** The owner of each of [itemIds] that exists. */
    suspend fun itemOwners(itemIds: Collection<String>): Map<String, String> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ItemsTable
                    .select(ItemsTable.id, ItemsTable.owner)
                    .where { ItemsTable.id inList itemIds }
                    .associate { it[ItemsTable.id] to it[ItemsTable.owner] }
            }
        }

    /** Files [itemIds] on [shelfId], or takes them off it; each book whose `shelves` changed gets a new revision. */
    suspend fun file(
        shelfId: String,
        itemIds: Collection<String>,
        isAdding: Boolean,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                val onShelf: Set<String> =
                    ItemShelvesTable
                        .select(ItemShelvesTable.itemId)
                        .where { (ItemShelvesTable.shelfId eq shelfId) and (ItemShelvesTable.itemId inList itemIds) }
                        .map { it[ItemShelvesTable.itemId] }
                        .toSet()
                val moved: List<String> = itemIds.filter { (it in onShelf) != isAdding }
                if (isAdding) {
                    ItemShelvesTable.batchInsert(moved.withIndex()) { (index, itemId) ->
                        this[ItemShelvesTable.itemId] = itemId
                        this[ItemShelvesTable.shelfId] = shelfId
                        this[ItemShelvesTable.added] = now + index
                    }
                } else {
                    ItemShelvesTable.deleteWhere { (ItemShelvesTable.shelfId eq shelfId) and (itemId inList moved) }
                }
                ItemsTable.update({ ItemsTable.id inList moved }) { it[version] = version + 1 }
            }
        }
    }

    /** The étagères go; their books stay, each with a new revision for the `shelves` it lost. */
    suspend fun delete(shelfIds: Collection<String>) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                val itemIds: List<String> =
                    ItemShelvesTable
                        .select(ItemShelvesTable.itemId)
                        .where { ItemShelvesTable.shelfId inList shelfIds }
                        .map { it[ItemShelvesTable.itemId] }
                        .distinct()
                ItemsTable.update({ ItemsTable.id inList itemIds }) { it[version] = version + 1 }
                ShelvesTable.deleteWhere { id inList shelfIds }
            }
        }
    }

    private suspend fun records(condition: () -> Op<Boolean>): List<ShelfRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ShelvesTable
                    .selectAll()
                    .where { condition() }
                    .orderBy(ShelvesTable.created to SortOrder.ASC, ShelvesTable.id to SortOrder.ASC)
                    .map { it.toShelfRecord() }
            }
        }

    private companion object {
        /** Postgres's `foreign_key_violation`. */
        const val FOREIGN_KEY_VIOLATION: String = "23503"

        val logger: Logger = LoggerFactory.getLogger(ShelvesRepository::class.java)
    }
}

private fun ResultRow.toShelfRecord(): ShelfRecord =
    ShelfRecord(
        id = this[ShelvesTable.id],
        version = this[ShelvesTable.version],
        owner = this[ShelvesTable.owner],
        name = this[ShelvesTable.name],
        description = this[ShelvesTable.description],
        visibility = this[ShelvesTable.visibility],
        color = this[ShelvesTable.color],
        created = this[ShelvesTable.created],
        updated = this[ShelvesTable.updated],
    )
