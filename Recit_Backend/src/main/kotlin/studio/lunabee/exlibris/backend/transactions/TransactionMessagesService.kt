package studio.lunabee.exlibris.backend.transactions

import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import java.time.Clock

/** The messages of an Échange, as inventaire.io's `get_messages.ts` and `post_message.ts`. */
class TransactionMessagesService(
    private val transactions: TransactionsRepository,
    private val repository: TransactionMessagesRepository,
    private val clock: Clock,
) {
    /**
     * `GET /api/transactions/messages`, the oldest first. Read by the Échange's two readers only, where inventaire.io
     * lets any signed-in reader read them.
     */
    suspend fun messages(
        userId: String,
        transactionId: String,
    ): TransactionMessages {
        side(transactionId, userId)
        return TransactionMessages(repository.ofTransaction(transactionId).map { it.document() })
    }

    /** `POST /api/transactions/messages`, on any state: the other side has something new to read. */
    suspend fun post(
        userId: String,
        body: JsonBody,
    ): MessagePosted {
        val transactionId: String = TransactionRules.id(body)
        val text: String = TransactionRules.message(body)
        val author: TransactionRole = side(transactionId, userId)
        val message =
            TransactionMessage(
                id = DocumentId.new(),
                transactionId = transactionId,
                userId = userId,
                message = text,
                created = clock.millis(),
            )
        repository.add(message, TransactionRead.after(author))
        val document: TransactionMessageDocument = message.document()
        return MessagePosted(id = document.id, rev = document.rev)
    }

    /** [userId]'s side of [transactionId], or `wrong user`. */
    private suspend fun side(
        transactionId: String,
        userId: String,
    ): TransactionRole {
        val transaction: TransactionRecord = transactions.find(transactionId) ?: throw ApiException.missingDocument()
        return transaction.role(userId) ?: throw TransactionRules.wrongUser()
    }
}
