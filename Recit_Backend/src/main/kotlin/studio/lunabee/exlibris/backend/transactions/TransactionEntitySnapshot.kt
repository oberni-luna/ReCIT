package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** The book's `snapshot.entity`: what its item snapshot said of its title, cover and authors at request time. */
@Serializable
data class TransactionEntitySnapshot(
    val title: String? = null,
    val image: String? = null,
    val authors: String? = null,
)
