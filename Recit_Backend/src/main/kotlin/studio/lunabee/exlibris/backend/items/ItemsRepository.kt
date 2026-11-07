package studio.lunabee.exlibris.backend.items

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.JoinType
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.core.statements.UpdateStatement
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

class ItemsRepository(
    private val database: Database,
) {
    /** `false` when the owner's account is gone: the foreign key said no. */
    suspend fun insert(item: ItemRecord): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) {
                    ItemsTable.insert {
                        it[id] = item.id
                        it[version] = item.version
                        it[owner] = item.owner
                        it[entity] = item.entity
                        it[transaction] = item.transaction.storedName
                        it[visibility] = item.visibility
                        it[details] = item.details
                        it[notes] = item.notes
                        it[created] = item.created
                    }
                    fileOnShelves(item.id, item.shelves, item.created)
                }
                true
            } catch (error: ExposedSQLException) {
                if (error.sqlState != FOREIGN_KEY_VIOLATION) throw error
                logger.info("A book was refused a missing owner or étagère: {}", error.message)
                false
            }
        }

    /** The books of [ids] that exist, whoever may see them, with every étagère they are on. */
    suspend fun find(ids: Collection<String>): List<ItemRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                records(ItemsTable.selectAll().where { ItemsTable.id inList ids }.toList(), viewerId = null)
            }
        }

    /**
     * The books of [ids] [viewerId] may see, the newest first, each with the étagères on it [viewerId] may see:
     * inventaire.io's `filterVisibleDocs`, then `removeUnauthorizedShelves`.
     */
    suspend fun visible(
        ids: Collection<String>,
        viewerId: String?,
    ): List<ItemRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val rows: List<ResultRow> =
                    ItemsTable
                        .selectAll()
                        .where {
                            (ItemsTable.id inList ids) and
                                Visibility.visibleTo(viewerId, ItemsTable.owner, ItemsTable.visibility)
                        }.orderBy(ItemsTable.created to SortOrder.DESC, ItemsTable.id to SortOrder.ASC)
                        .toList()
                records(rows, viewerId)
            }
        }

    /** The owner of each of [shelfIds] that exists. */
    suspend fun shelfOwners(shelfIds: Collection<String>): Map<String, String> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ShelvesTable
                    .select(ShelvesTable.id, ShelvesTable.owner)
                    .where { ShelvesTable.id inList shelfIds }
                    .associate { it[ShelvesTable.id] to it[ShelvesTable.owner] }
            }
        }

    /** Writes [change] on each of [ids], moving their revision and `updated`. */
    suspend fun update(
        ids: Collection<String>,
        change: ItemChange,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                ItemsTable.update({ ItemsTable.id inList ids }) {
                    it[version] = version + 1
                    it[updated] = now
                    it.write(change)
                }
                if (change is ItemChange.Shelves) {
                    ItemShelvesTable.deleteWhere { itemId inList ids }
                    ids.forEach { fileOnShelves(it, change.shelfIds, now) }
                }
            }
        }
    }

    /** Off every étagère with them. */
    suspend fun delete(ids: Collection<String>) {
        withContext(Dispatchers.IO) {
            transaction(database) { ItemsTable.deleteWhere { id inList ids } }
        }
    }

    private fun fileOnShelves(
        itemId: String,
        shelfIds: List<String>,
        now: Long,
    ) {
        ItemShelvesTable.batchInsert(shelfIds.withIndex()) { (index, shelfId) ->
            this[ItemShelvesTable.itemId] = itemId
            this[ItemShelvesTable.shelfId] = shelfId
            this[ItemShelvesTable.added] = now + index
        }
    }

    /** [rows] as records, each with the étagères on it — those [viewerId] may see, when there is a viewer. */
    private fun records(
        rows: List<ResultRow>,
        viewerId: String?,
    ): List<ItemRecord> {
        val itemIds: List<String> = rows.map { it[ItemsTable.id] }
        val onShelf = ItemShelvesTable.itemId inList itemIds
        val shelves: Map<String, List<String>> =
            ItemShelvesTable
                .join(ShelvesTable, JoinType.INNER, ItemShelvesTable.shelfId, ShelvesTable.id)
                .select(ItemShelvesTable.itemId, ItemShelvesTable.shelfId)
                .where {
                    if (viewerId == null) {
                        onShelf
                    } else {
                        onShelf and Visibility.visibleTo(viewerId, ShelvesTable.owner, ShelvesTable.visibility)
                    }
                }.orderBy(ItemShelvesTable.added to SortOrder.ASC, ItemShelvesTable.shelfId to SortOrder.ASC)
                .groupBy({ it[ItemShelvesTable.itemId] }, { it[ItemShelvesTable.shelfId] })
        return rows.map { it.toItemRecord(shelves[it[ItemsTable.id]].orEmpty()) }
    }

    private companion object {
        /** Postgres's `foreign_key_violation`. */
        const val FOREIGN_KEY_VIOLATION: String = "23503"

        val logger: Logger = LoggerFactory.getLogger(ItemsRepository::class.java)
    }
}

private fun UpdateStatement.write(change: ItemChange) {
    when (change) {
        is ItemChange.Transaction -> this[ItemsTable.transaction] = change.mode.storedName
        is ItemChange.Visibility -> this[ItemsTable.visibility] = change.keys
        is ItemChange.Details -> this[ItemsTable.details] = change.text
        is ItemChange.Notes -> this[ItemsTable.notes] = change.text
        is ItemChange.Entity -> this[ItemsTable.entity] = change.uri
        is ItemChange.Shelves, ItemChange.Untouched -> Unit
    }
}

private fun ResultRow.toItemRecord(shelves: List<String>): ItemRecord =
    ItemRecord(
        id = this[ItemsTable.id],
        version = this[ItemsTable.version],
        owner = this[ItemsTable.owner],
        entity = this[ItemsTable.entity],
        transaction = requireNotNull(TransactionMode.of(this[ItemsTable.transaction])) { "unknown transaction mode" },
        visibility = this[ItemsTable.visibility],
        details = this[ItemsTable.details],
        notes = this[ItemsTable.notes],
        previousEntities = this[ItemsTable.previousEntities],
        created = this[ItemsTable.created],
        updated = this[ItemsTable.updated],
        shelves = shelves,
    )
