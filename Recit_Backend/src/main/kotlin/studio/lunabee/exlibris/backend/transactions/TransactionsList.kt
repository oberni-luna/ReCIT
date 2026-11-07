package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** `GET /api/transactions`. */
@Serializable
data class TransactionsList(
    val transactions: List<TransactionDocument>,
)
