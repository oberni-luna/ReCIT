package studio.lunabee.exlibris.backend.transactions

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.items.TransactionMode
import studio.lunabee.exlibris.backend.plugins.ApiException

/** inventaire.io's rules for moving an Échange (`update_state.ts`, `validateTransactionPossibleState`). */
object TransactionMoves {
    /** [userId]'s side, when it may move [transaction] to [state]: `wrong user` otherwise. */
    fun actor(
        transaction: TransactionRecord,
        state: TransactionState,
        userId: String,
    ): TransactionRole =
        transaction.role(userId)?.takeIf { state.actor.allows(it) } ?: throw TransactionRules.wrongUser()

    /** Whether [state] follows [transaction]'s, and `returned` only ends a loan. */
    fun requirePossible(
        transaction: TransactionRecord,
        state: TransactionState,
    ) {
        if (state !in transaction.state.next) throw ApiException(HttpStatusCode.BadRequest, "invalid state update")
        if (state == TransactionState.RETURNED && transaction.mode != TransactionMode.LENDING) {
            throw ApiException(HttpStatusCode.BadRequest, "transaction and state mismatch")
        }
    }
}
