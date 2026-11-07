package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** `GET /api/transactions/messages`. */
@Serializable
data class TransactionMessages(
    val messages: List<TransactionMessageDocument>,
)
