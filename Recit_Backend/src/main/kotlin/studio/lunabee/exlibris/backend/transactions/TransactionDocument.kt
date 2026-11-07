package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** An Échange as inventaire.io answers it, the whole CouchDB document. */
@Serializable
data class TransactionDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val item: String,
    val owner: String,
    val requester: String,
    val transaction: String,
    val state: String,
    val created: Long,
    val actions: List<TransactionAction>,
    val read: TransactionRead,
    val snapshot: TransactionSnapshot,
)
