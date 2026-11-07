package studio.lunabee.exlibris.backend.transactions

import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.items.TransactionMode

/** A `transactions` row with its actions in the order they happened. */
data class TransactionRecord(
    val id: String,
    val version: Int,
    val item: String,
    val owner: String,
    val requester: String,
    val mode: TransactionMode,
    val state: TransactionState,
    val created: Long,
    val actions: List<TransactionAction>,
    val read: TransactionRead,
    val snapshot: TransactionSnapshot,
) {
    /**
     * Still waiting on someone, inventaire.io's `transactionIsActive`: requested, accepted, or a loan confirmed and
     * not yet returned. What a deleted account's Échanges are cancelled from.
     */
    val isActive: Boolean
        get() =
            state == TransactionState.REQUESTED ||
                state == TransactionState.ACCEPTED ||
                (state == TransactionState.CONFIRMED && mode == TransactionMode.LENDING)

    /** A gift or a sale moves the book to the requester once confirmed; a loan only lends it. */
    val movesItemWhenConfirmed: Boolean
        get() = mode != TransactionMode.LENDING

    /** [userId]'s side, or `null` when they are on neither. */
    fun role(userId: String): TransactionRole? =
        when (userId) {
            owner -> TransactionRole.OWNER
            requester -> TransactionRole.REQUESTER
            else -> null
        }

    /** Moved to [state] by [actor] at [now], as inventaire.io's `stateUpdater` writes it. */
    fun moved(
        state: TransactionState,
        actor: TransactionRole,
        now: Long,
    ): TransactionRecord =
        copy(
            version = version + 1,
            state = state,
            actions =
                actions +
                    TransactionAction(
                        action = state.storedName,
                        timestamp = now,
                        actor = actor.storedName.takeIf { state.actor == TransactionActor.BOTH },
                    ),
            read = TransactionRead.after(actor),
        )

    fun document(): TransactionDocument =
        TransactionDocument(
            id = id,
            rev = DocumentId.revision(id, version),
            item = item,
            owner = owner,
            requester = requester,
            transaction = mode.storedName,
            state = state.storedName,
            created = created,
            actions = actions,
            read = read,
            snapshot = snapshot,
        )
}
