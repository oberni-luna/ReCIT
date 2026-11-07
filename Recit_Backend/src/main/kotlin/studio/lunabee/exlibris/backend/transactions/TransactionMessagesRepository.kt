package studio.lunabee.exlibris.backend.transactions

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.neq
import org.jetbrains.exposed.v1.core.or
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import studio.lunabee.exlibris.backend.db.TransactionMessagesTable
import studio.lunabee.exlibris.backend.db.TransactionsTable

/** The messages of the Échanges, inventaire.io's transaction `comments`. */
class TransactionMessagesRepository(
    private val database: Database,
) {
    /** [transactionId]'s messages, the oldest first. */
    suspend fun ofTransaction(transactionId: String): List<TransactionMessage> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                TransactionMessagesTable
                    .selectAll()
                    .where { TransactionMessagesTable.transactionId eq transactionId }
                    .orderBy(
                        TransactionMessagesTable.created to SortOrder.ASC,
                        TransactionMessagesTable.id to SortOrder.ASC,
                    ).map {
                        TransactionMessage(
                            id = it[TransactionMessagesTable.id],
                            transactionId = it[TransactionMessagesTable.transactionId],
                            userId = it[TransactionMessagesTable.userId],
                            message = it[TransactionMessagesTable.message],
                            created = it[TransactionMessagesTable.created],
                        )
                    }
            }
        }

    /**
     * Adds [message], and sets its transaction's flags to [read]; the transaction's revision moves only when they
     * change, as inventaire.io's `updateReadForNewMessage` spares the write.
     */
    suspend fun add(
        message: TransactionMessage,
        read: TransactionRead,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                insertMessage(message)
                val changesRead: Op<Boolean> =
                    (TransactionsTable.readOwner neq read.owner) or (TransactionsTable.readRequester neq read.requester)
                TransactionsTable.update({ (TransactionsTable.id eq message.transactionId) and changesRead }) {
                    it[version] = version + 1
                    it[readOwner] = read.owner
                    it[readRequester] = read.requester
                }
            }
        }
    }
}

/** Inserts [message]; inside a transaction, where an Échange's request writes its first message too. */
internal fun insertMessage(message: TransactionMessage) {
    TransactionMessagesTable.insert {
        it[id] = message.id
        it[version] = 1
        it[transactionId] = message.transactionId
        it[userId] = message.userId
        it[this.message] = message.message
        it[created] = message.created
    }
}
