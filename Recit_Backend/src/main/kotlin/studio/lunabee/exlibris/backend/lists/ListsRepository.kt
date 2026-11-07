package studio.lunabee.exlibris.backend.lists

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.exceptions.ExposedSQLException
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.db.ListsTable
import studio.lunabee.exlibris.backend.db.Visibility

/** The lists themselves; their elements are [ListElementsRepository]'s. */
class ListsRepository(
    private val database: Database,
) {
    /** `false` when the creator's account is gone: the foreign key said no. */
    suspend fun insert(list: ListRecord): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) {
                    ListsTable.insert {
                        it[id] = list.id
                        it[version] = list.version
                        it[creator] = list.creator
                        it[name] = list.name
                        it[description] = list.description
                        it[visibility] = list.visibility
                        it[type] = list.type.storedName
                        it[created] = list.created
                    }
                }
                true
            } catch (error: ExposedSQLException) {
                if (error.sqlState != FOREIGN_KEY_VIOLATION) throw error
                logger.info("A list was refused a missing creator: {}", error.message)
                false
            }
        }

    /** The lists of [ids] that exist, whoever may see them. */
    suspend fun find(ids: Collection<String>): List<ListRecord> = records { ListsTable.id inList ids }

    /** [creators]' lists [viewerId] may see, the newest first, as inventaire.io's `paginate` sorts them. */
    suspend fun visibleOf(
        creators: Collection<String>,
        viewerId: String?,
    ): List<ListRecord> =
        records {
            (ListsTable.creator inList creators) and
                Visibility.visibleTo(viewerId, ListsTable.creator, ListsTable.visibility)
        }

    /** Writes [fields] and moves the list's revision and `updated`. */
    suspend fun update(
        listId: String,
        fields: ListFields,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                ListsTable.update({ ListsTable.id eq listId }) {
                    it[version] = version + 1
                    it[name] = fields.name
                    it[description] = fields.description
                    it[visibility] = fields.visibility
                    it[updated] = now
                }
            }
        }
    }

    /** The lists go, and their elements with them (`ON DELETE CASCADE`). */
    suspend fun delete(listIds: Collection<String>) {
        withContext(Dispatchers.IO) {
            transaction(database) { ListsTable.deleteWhere { id inList listIds } }
        }
    }

    private suspend fun records(condition: () -> Op<Boolean>): List<ListRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ListsTable
                    .selectAll()
                    .where { condition() }
                    .orderBy(ListsTable.created to SortOrder.DESC, ListsTable.id to SortOrder.ASC)
                    .map { it.toListRecord() }
            }
        }

    private companion object {
        /** Postgres's `foreign_key_violation`. */
        const val FOREIGN_KEY_VIOLATION: String = "23503"

        val logger: Logger = LoggerFactory.getLogger(ListsRepository::class.java)
    }
}

private fun ResultRow.toListRecord(): ListRecord =
    ListRecord(
        id = this[ListsTable.id],
        version = this[ListsTable.version],
        creator = this[ListsTable.creator],
        name = this[ListsTable.name],
        description = this[ListsTable.description],
        visibility = this[ListsTable.visibility],
        type = requireNotNull(ListType.from(this[ListsTable.type])) { "a list of an unknown type" },
        created = this[ListsTable.created],
        updated = this[ListsTable.updated],
    )
