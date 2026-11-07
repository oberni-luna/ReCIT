package studio.lunabee.exlibris.backend.lists

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.count
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.JdbcTransaction
import org.jetbrains.exposed.v1.jdbc.batchInsert
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.db.ListElementsTable

/** The lists' elements, as the routes read and write them; their URIs' nightly check is [ElementUrisRepository]'s. */
class ListElementsRepository(
    private val database: Database,
) {
    /** Every element of [listIds], in ordinal order. */
    suspend fun ofLists(listIds: Collection<String>): List<ListElementRecord> =
        records { ListElementsTable.listId inList listIds }

    /** The elements of [listId] whose URI is one of [uris]. */
    suspend fun held(
        listId: String,
        uris: Collection<String>,
    ): List<ListElementRecord> =
        records { (ListElementsTable.listId eq listId) and (ListElementsTable.uri inList uris) }

    suspend fun find(elementId: String): ListElementRecord? =
        records { ListElementsTable.id eq elementId }.singleOrNull()

    /** How many elements each of [listIds] holds; a list without any is left out. */
    suspend fun counts(listIds: Collection<String>): Map<String, Int> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val count = ListElementsTable.id.count()
                ListElementsTable
                    .select(ListElementsTable.listId, count)
                    .where { ListElementsTable.listId inList listIds }
                    .groupBy(ListElementsTable.listId)
                    .associate { it[ListElementsTable.listId] to it[count].toInt() }
            }
        }

    /**
     * Adds [uris] to [listId], each after the last, as inventaire.io's `createListingElements` numbers them. A URI
     * another request added in the meantime is skipped; the elements created are answered.
     */
    suspend fun add(
        listId: String,
        uris: List<String>,
        now: Long,
    ): List<ListElementRecord> {
        if (uris.isEmpty()) return emptyList()
        return withContext(Dispatchers.IO) {
            transaction(database) {
                val ordinals: List<String> =
                    uris.runningFold(highestOrdinal(listId)) { last, _ -> LexicographicOrdinals.next(last) }.drop(1)
                val ids: List<String> = uris.map { DocumentId.new() }
                ListElementsTable.batchInsert(uris.indices, ignore = true) { index ->
                    this[ListElementsTable.id] = ids[index]
                    this[ListElementsTable.version] = 1
                    this[ListElementsTable.listId] = listId
                    this[ListElementsTable.uri] = uris[index]
                    this[ListElementsTable.ordinal] = ordinals[index]
                    this[ListElementsTable.created] = now
                    this[ListElementsTable.uriChecked] = now
                }
                val created: Map<String, ListElementRecord> =
                    ListElementsTable
                        .selectAll()
                        .where { ListElementsTable.id inList ids }
                        .associate { it[ListElementsTable.id] to it.toListElementRecord() }
                ids.mapNotNull { created[it] }
            }
        }
    }

    /**
     * Writes [comment] on [elementId], and with [moveTo] moves it to the end of that list, as `update-element` does;
     * the element as it now is.
     */
    suspend fun update(
        elementId: String,
        comment: String?,
        moveTo: String?,
        now: Long,
    ): ListElementRecord =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val ordinal: String? = moveTo?.let { LexicographicOrdinals.next(highestOrdinal(it)) }
                ListElementsTable.update({ ListElementsTable.id eq elementId }) {
                    it[version] = version + 1
                    it[this.comment] = comment
                    if (moveTo != null && ordinal != null) {
                        it[listId] = moveTo
                        it[this.ordinal] = ordinal
                    }
                    it[updated] = now
                }
                ListElementsTable
                    .selectAll()
                    .where { ListElementsTable.id eq elementId }
                    .single()
                    .toListElementRecord()
            }
        }

    suspend fun delete(elementIds: Collection<String>) {
        withContext(Dispatchers.IO) {
            transaction(database) { ListElementsTable.deleteWhere { id inList elementIds } }
        }
    }

    /**
     * `getListingHighestOrdinal`, in inventaire.io's byte order rather than the database's collation: `1` for a list
     * without elements.
     */
    private fun JdbcTransaction.highestOrdinal(listId: String): String =
        ListElementsTable
            .select(ListElementsTable.ordinal)
            .where { ListElementsTable.listId eq listId }
            .maxOfOrNull { it[ListElementsTable.ordinal] }
            ?: LexicographicOrdinals.EMPTY_LIST

    private suspend fun records(condition: () -> Op<Boolean>): List<ListElementRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ListElementsTable
                    .selectAll()
                    .where { condition() }
                    .map { it.toListElementRecord() }
                    .sortedWith(compareBy({ it.listId }, { it.ordinal }, { it.id }))
            }
        }
}

internal fun ResultRow.toListElementRecord(): ListElementRecord =
    ListElementRecord(
        id = this[ListElementsTable.id],
        version = this[ListElementsTable.version],
        listId = this[ListElementsTable.listId],
        uri = this[ListElementsTable.uri],
        ordinal = this[ListElementsTable.ordinal],
        comment = this[ListElementsTable.comment],
        previousUris = this[ListElementsTable.previousUris],
        created = this[ListElementsTable.created],
        updated = this[ListElementsTable.updated],
    )
