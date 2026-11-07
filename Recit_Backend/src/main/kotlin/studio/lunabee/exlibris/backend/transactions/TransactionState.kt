package studio.lunabee.exlibris.backend.transactions

/**
 * inventaire.io's `transactionStates` (`models/attributes/transaction.ts`): who may move an Échange to each state, and
 * the states it may move to from each. A `confirmed` Échange may still be `cancelled`, as on Codeberg.
 */
enum class TransactionState(
    val storedName: String,
    val actor: TransactionActor,
) {
    REQUESTED("requested", TransactionActor.REQUESTER),
    ACCEPTED("accepted", TransactionActor.OWNER),
    DECLINED("declined", TransactionActor.OWNER),
    CONFIRMED("confirmed", TransactionActor.REQUESTER),
    RETURNED("returned", TransactionActor.OWNER),
    CANCELLED("cancelled", TransactionActor.BOTH),
    ;

    val next: Set<TransactionState>
        get() =
            when (this) {
                REQUESTED -> setOf(ACCEPTED, DECLINED, CANCELLED)
                ACCEPTED -> setOf(CONFIRMED, CANCELLED)
                CONFIRMED -> setOf(RETURNED, CANCELLED)
                DECLINED, RETURNED, CANCELLED -> emptySet()
            }

    companion object {
        fun of(storedName: String): TransactionState? = entries.firstOrNull { it.storedName == storedName }
    }
}
