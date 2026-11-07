package studio.lunabee.exlibris.backend.transactions

/** Who may move an Échange to a state, inventaire.io's `transactionStates[state].actor`. */
enum class TransactionActor {
    OWNER,
    REQUESTER,
    BOTH,
    ;

    fun allows(role: TransactionRole): Boolean =
        when (this) {
            OWNER -> role == TransactionRole.OWNER
            REQUESTER -> role == TransactionRole.REQUESTER
            BOTH -> true
        }
}
