package studio.lunabee.exlibris.backend.items

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.exists
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.less
import org.jetbrains.exposed.v1.core.not
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.batchInsert
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import org.jetbrains.exposed.v1.jdbc.upsert
import studio.lunabee.exlibris.backend.db.EntitySnapshotsTable
import studio.lunabee.exlibris.backend.db.ItemsTable
import studio.lunabee.exlibris.backend.db.SnapshotWorksTable

class SnapshotsRepository(
    private val database: Database,
) {
    /** Writes [entity]'s snapshot over the one stored under its URI, its works with it. */
    suspend fun save(entity: EntitySnapshot) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                EntitySnapshotsTable.upsert {
                    it[uri] = entity.uri
                    it[title] = entity.snapshot.title
                    it[subtitle] = entity.snapshot.subtitle
                    it[lang] = entity.snapshot.lang
                    it[authors] = entity.snapshot.authors
                    it[image] = entity.snapshot.image
                    it[series] = entity.snapshot.series
                    it[ordinal] = entity.snapshot.ordinal
                    it[isbn13] = entity.snapshot.isbn13
                    it[isbn10] = entity.snapshot.isbn10
                    it[worksUris] = entity.snapshot.worksUris
                    it[authorsUris] = entity.snapshot.authorsUris
                    it[seriesUris] = entity.snapshot.seriesUris
                    it[refreshed] = entity.refreshed
                }
                SnapshotWorksTable.deleteWhere { uri eq entity.uri }
                SnapshotWorksTable.batchInsert(entity.works.withIndex()) { (position, work) ->
                    this[SnapshotWorksTable.uri] = entity.uri
                    this[SnapshotWorksTable.workUri] = work.uri
                    this[SnapshotWorksTable.position] = position
                    this[SnapshotWorksTable.authors] = work.authors
                    this[SnapshotWorksTable.genres] = work.genres
                    this[SnapshotWorksTable.subjects] = work.subjects
                }
            }
        }
    }

    /** The snapshots stored under [uris], by URI. */
    suspend fun find(uris: Collection<String>): Map<String, ItemSnapshot> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                EntitySnapshotsTable
                    .selectAll()
                    .where { EntitySnapshotsTable.uri inList uris.distinct() }
                    .associate { it[EntitySnapshotsTable.uri] to it.toItemSnapshot() }
            }
        }

    /** Those of [uris] read before [before], or every stored one when [uris] is `null`, the oldest first. */
    suspend fun readBefore(
        before: Long,
        uris: Collection<String>? = null,
    ): List<String> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                EntitySnapshotsTable
                    .select(EntitySnapshotsTable.uri)
                    .where {
                        val old = EntitySnapshotsTable.refreshed less before
                        uris?.let { old and (EntitySnapshotsTable.uri inList it.distinct()) } ?: old
                    }.orderBy(EntitySnapshotsTable.refreshed to SortOrder.ASC)
                    .map { it[EntitySnapshotsTable.uri] }
            }
        }

    /** Marks [uris] read at [now] without changing them: inventaire.io no longer knows them, they keep their last. */
    suspend fun markRead(
        uris: Collection<String>,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                EntitySnapshotsTable.update({ EntitySnapshotsTable.uri inList uris }) { it[refreshed] = now }
            }
        }
    }

    /**
     * inventaire.io's `updateItemsEntityAfterMerge`: the books of [from] move to [to], which keeps [from] at the head
     * of their `previousEntities`. [to]'s snapshot is stored first.
     */
    suspend fun moveItems(
        from: String,
        to: String,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                ItemsTable
                    .select(ItemsTable.id, ItemsTable.previousEntities)
                    .where { ItemsTable.entity eq from }
                    .forUpdate()
                    .map { it[ItemsTable.id] to it[ItemsTable.previousEntities].orEmpty() }
                    .forEach { (itemId, previous) ->
                        ItemsTable.update({ ItemsTable.id eq itemId }) {
                            it[entity] = to
                            it[previousEntities] = listOf(from) + previous
                            it[version] = version + 1
                        }
                    }
            }
        }
    }

    /** Drops the snapshots no book is of any more (decision 8): their works go with them. */
    suspend fun deleteUnused(): Int =
        withContext(Dispatchers.IO) {
            transaction(database) {
                EntitySnapshotsTable.deleteWhere {
                    not(
                        exists(
                            ItemsTable.select(ItemsTable.id).where { ItemsTable.entity eq EntitySnapshotsTable.uri },
                        ),
                    )
                }
            }
        }
}

private fun ResultRow.toItemSnapshot(): ItemSnapshot =
    ItemSnapshot(
        title = this[EntitySnapshotsTable.title],
        subtitle = this[EntitySnapshotsTable.subtitle],
        lang = this[EntitySnapshotsTable.lang],
        authors = this[EntitySnapshotsTable.authors],
        image = this[EntitySnapshotsTable.image],
        series = this[EntitySnapshotsTable.series],
        ordinal = this[EntitySnapshotsTable.ordinal],
        worksUris = this[EntitySnapshotsTable.worksUris],
        authorsUris = this[EntitySnapshotsTable.authorsUris],
        seriesUris = this[EntitySnapshotsTable.seriesUris],
        isbn13 = this[EntitySnapshotsTable.isbn13],
        isbn10 = this[EntitySnapshotsTable.isbn10],
    )
