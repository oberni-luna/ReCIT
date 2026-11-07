package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** `request`'s answer: the Échange created. */
@Serializable
data class TransactionAnswer(
    val transaction: TransactionDocument,
)
