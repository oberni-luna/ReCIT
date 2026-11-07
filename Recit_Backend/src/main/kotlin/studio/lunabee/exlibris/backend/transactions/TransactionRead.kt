package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** An Échange's `read`: `false` for the side with something new to read, as inventaire.io's `updateReadStates`. */
@Serializable
data class TransactionRead(
    val requester: Boolean,
    val owner: Boolean,
) {
    companion object {
        /** After [actor] acted or wrote: read by them, unread by the other side. */
        fun after(actor: TransactionRole): TransactionRead =
            TransactionRead(requester = actor == TransactionRole.REQUESTER, owner = actor == TransactionRole.OWNER)
    }
}
