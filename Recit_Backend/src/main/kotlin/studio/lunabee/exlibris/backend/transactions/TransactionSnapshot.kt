package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/**
 * inventaire.io's transaction `snapshot`, taken at request time so the Échange stays readable once the book is no
 * longer visible or an account is gone (#75 decision 6).
 */
@Serializable
data class TransactionSnapshot(
    val item: TransactionItemSnapshot,
    val entity: TransactionEntitySnapshot,
    val owner: TransactionUserSnapshot,
    val requester: TransactionUserSnapshot,
)
