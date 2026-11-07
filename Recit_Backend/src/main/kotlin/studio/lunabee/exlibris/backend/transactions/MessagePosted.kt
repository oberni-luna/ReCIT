package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** `POST /api/transactions/messages`' answer: CouchDB's answer to the comment's creation, as inventaire.io sends it. */
@Serializable
data class MessagePosted(
    val id: String,
    val rev: String,
    val ok: Boolean = true,
)
