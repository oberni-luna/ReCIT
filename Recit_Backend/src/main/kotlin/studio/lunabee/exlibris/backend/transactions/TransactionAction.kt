package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** One of an Échange's `actions`: the state it moved to, when, and who did it when either side may (`cancelled`). */
@Serializable
data class TransactionAction(
    val action: String,
    val timestamp: Long,
    val actor: String? = null,
)
