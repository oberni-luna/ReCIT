package studio.lunabee.exlibris.backend.lists

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.less
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import studio.lunabee.exlibris.backend.db.ListElementsTable

/** The elements' URIs, as the nightly job checks them against inventaire.io's redirects. */
class ElementUrisRepository(
    private val database: Database,
) {
    /** The URIs of elements last checked before [time], each once. */
    suspend fun checkedBefore(time: Long): List<String> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                ListElementsTable
                    .select(ListElementsTable.uri)
                    .where { ListElementsTable.uriChecked less time }
                    .withDistinct()
                    .map { it[ListElementsTable.uri] }
            }
        }

    suspend fun markChecked(
        uris: Collection<String>,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                ListElementsTable.update({ ListElementsTable.uri inList uris }) { it[uriChecked] = now }
            }
        }
    }

    /**
     * Moves every element of [from] to [to], keeping [from] first in its `previousUris`, as inventaire.io's
     * `updateElementsUrisAfterMerge`. In a list that already holds [to], the element of [from] goes instead, its
     * comment kept on the other when that one has none.
     */
    suspend fun redirect(
        from: String,
        to: String,
        now: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                val targets: Map<String, ListElementRecord> =
                    ListElementsTable
                        .selectAll()
                        .where { ListElementsTable.uri eq to }
                        .map { it.toListElementRecord() }
                        .associateBy { it.listId }
                ListElementsTable
                    .selectAll()
                    .where { ListElementsTable.uri eq from }
                    .map { it.toListElementRecord() }
                    .forEach { element ->
                        val target: ListElementRecord? = targets[element.listId]
                        if (target == null) {
                            ListElementsTable.update({ ListElementsTable.id eq element.id }) {
                                it[version] = version + 1
                                it[uri] = to
                                it[previousUris] = listOf(from) + element.previousUris.orEmpty()
                                it[uriChecked] = now
                            }
                        } else {
                            if (target.comment.isNullOrEmpty() && !element.comment.isNullOrEmpty()) {
                                ListElementsTable.update({ ListElementsTable.id eq target.id }) {
                                    it[version] = version + 1
                                    it[comment] = element.comment
                                    it[updated] = now
                                }
                            }
                            ListElementsTable.deleteWhere { (id eq element.id) and (uri eq from) }
                        }
                    }
            }
        }
    }
}
