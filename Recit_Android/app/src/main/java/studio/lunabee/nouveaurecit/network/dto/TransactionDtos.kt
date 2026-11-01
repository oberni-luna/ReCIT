package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * `POST /api/transactions/request`: the copy asked for, and the first message. Nothing else — the
 * server reads the transaction's type off the item (`createTransactionDoc` copies
 * `itemDoc.transaction`) and refuses a copy that is only inventoried.
 */
@Serializable
data class TransactionRequestDto(
    val item: String,
    val message: String,
)

/** The answer: the created transaction under `transaction`, maybe with `warnings` beside it, ignored. */
@Serializable
data class TransactionRequestResponseDto(
    val transaction: CreatedTransactionDto,
)

/** What the request form reads of the transaction it created: that there is one. */
@Serializable
data class CreatedTransactionDto(
    @SerialName("_id") val id: String,
    val transaction: String? = null,
    val state: String? = null,
)
