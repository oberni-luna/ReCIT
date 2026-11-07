package studio.lunabee.exlibris.backend.transactions

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.JdbcTransaction
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import studio.lunabee.exlibris.backend.db.ItemsTable
import studio.lunabee.exlibris.backend.db.TransactionsTable
import studio.lunabee.exlibris.backend.db.UsersTable
import studio.lunabee.exlibris.backend.db.Visibility
import studio.lunabee.exlibris.backend.items.TransactionMode

/** What an Échange is about, read where it lives: the book asked for, and the two readers' names and pictures. */
class TransactionSubjectsRepository(
    private val database: Database,
) {
    /** The book [itemId] as [requesterId] would ask for it, or `null` when there is none. */
    suspend fun requestedItem(
        itemId: String,
        requesterId: String,
    ): RequestedItem? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val row: ResultRow =
                    ItemsTable.selectAll().where { ItemsTable.id eq itemId }.singleOrNull() ?: return@transaction null
                val isVisible: Boolean =
                    !ItemsTable
                        .select(ItemsTable.id)
                        .where {
                            (ItemsTable.id eq itemId) and
                                Visibility.visibleTo(requesterId, ItemsTable.owner, ItemsTable.visibility)
                        }.empty()
                RequestedItem(
                    id = itemId,
                    owner = row[ItemsTable.owner],
                    entity = row[ItemsTable.entity],
                    mode = requireNotNull(TransactionMode.of(row[ItemsTable.transaction])) { "unknown mode" },
                    details = row[ItemsTable.details],
                    isVisible = isVisible,
                    isBusy = holdsItem(itemId),
                )
            }
        }

    /** Whether an Échange holds [itemId] `busy`. */
    suspend fun isBusy(itemId: String): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) { holdsItem(itemId) }
        }

    /** The name and picture of each of [userIds] whose account exists. */
    suspend fun readers(userIds: Collection<String>): Map<String, TransactionUserSnapshot> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                UsersTable
                    .select(UsersTable.id, UsersTable.username, UsersTable.picture)
                    .where { UsersTable.id inList userIds }
                    .associate {
                        it[UsersTable.id] to TransactionUserSnapshot(it[UsersTable.username], it[UsersTable.picture])
                    }
            }
        }

    private fun JdbcTransaction.holdsItem(itemId: String): Boolean =
        !TransactionsTable
            .select(TransactionsTable.id)
            .where { (TransactionsTable.item eq itemId) and TransactionsTable.holdsItem() }
            .empty()
}
