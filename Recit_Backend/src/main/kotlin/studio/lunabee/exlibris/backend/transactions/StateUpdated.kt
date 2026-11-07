package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** `update-state`'s answer: `ok`, and the Échange as it now is. */
@Serializable
data class StateUpdated(
    val transaction: TransactionDocument,
    val ok: Boolean = true,
)
