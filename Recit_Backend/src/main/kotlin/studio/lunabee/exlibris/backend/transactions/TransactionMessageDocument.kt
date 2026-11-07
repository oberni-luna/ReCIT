package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** A message as inventaire.io answers it: a transaction `comment`. */
@Serializable
data class TransactionMessageDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val user: String,
    val message: String,
    val created: Long,
    val transaction: String,
)
