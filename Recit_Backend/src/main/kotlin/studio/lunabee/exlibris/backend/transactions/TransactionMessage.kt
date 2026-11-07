package studio.lunabee.exlibris.backend.transactions

import studio.lunabee.exlibris.backend.db.DocumentId

/** A `transaction_messages` row. A message is never changed: its revision stays the first. */
data class TransactionMessage(
    val id: String,
    val transactionId: String,
    val userId: String,
    val message: String,
    val created: Long,
) {
    fun document(): TransactionMessageDocument =
        TransactionMessageDocument(
            id = id,
            rev = DocumentId.revision(id, 1),
            user = userId,
            message = message,
            created = created,
            transaction = transactionId,
        )
}
