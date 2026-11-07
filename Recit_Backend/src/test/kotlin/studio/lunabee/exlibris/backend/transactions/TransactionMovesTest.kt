package studio.lunabee.exlibris.backend.transactions

import studio.lunabee.exlibris.backend.items.TransactionMode
import studio.lunabee.exlibris.backend.plugins.ApiException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class TransactionMovesTest {
    @Test
    fun `every state follows only the states inventaire allows, a loan alone ending returned`() {
        val allowed: Map<TransactionState, Set<TransactionState>> =
            mapOf(
                TransactionState.REQUESTED to
                    setOf(TransactionState.ACCEPTED, TransactionState.DECLINED, TransactionState.CANCELLED),
                TransactionState.ACCEPTED to setOf(TransactionState.CONFIRMED, TransactionState.CANCELLED),
                TransactionState.CONFIRMED to setOf(TransactionState.RETURNED, TransactionState.CANCELLED),
            )
        val moves: List<Pair<TransactionState, TransactionState>> =
            TransactionState.entries.flatMap { from -> TransactionState.entries.map { to -> from to to } }
        val (possible, impossible) = moves.partition { (from, to) -> to in allowed[from].orEmpty() }

        possible.forEach { (from, to) ->
            TransactionMoves.requirePossible(
                transaction(from, TransactionMode.LENDING),
                to,
            )
        }
        possible.filter { (_, to) -> to != TransactionState.RETURNED }.forEach { (from, to) ->
            TransactionMoves.requirePossible(transaction(from, TransactionMode.GIVING), to)
        }
        impossible.forEach { (from, to) ->
            assertFailsWith<ApiException>("$from to $to") {
                TransactionMoves.requirePossible(transaction(from, TransactionMode.LENDING), to)
            }
        }
        assertEquals(
            "transaction and state mismatch",
            assertFailsWith<ApiException> {
                TransactionMoves.requirePossible(
                    transaction(TransactionState.CONFIRMED, TransactionMode.SELLING),
                    TransactionState.RETURNED,
                )
            }.verbose,
        )
    }

    @Test
    fun `each state is reached by its side alone, cancelled by both, nobody else`() {
        val transaction: TransactionRecord = transaction(TransactionState.REQUESTED, TransactionMode.LENDING)
        val owners: List<TransactionState> =
            listOf(TransactionState.ACCEPTED, TransactionState.DECLINED, TransactionState.RETURNED)
        val requesters: List<TransactionState> = listOf(TransactionState.REQUESTED, TransactionState.CONFIRMED)

        owners.forEach { state ->
            assertEquals(TransactionRole.OWNER, TransactionMoves.actor(transaction, state, OWNER))
            assertFailsWith<ApiException> { TransactionMoves.actor(transaction, state, REQUESTER) }
        }
        requesters.forEach { state ->
            assertEquals(TransactionRole.REQUESTER, TransactionMoves.actor(transaction, state, REQUESTER))
            assertFailsWith<ApiException> { TransactionMoves.actor(transaction, state, OWNER) }
        }
        assertEquals(TransactionRole.OWNER, TransactionMoves.actor(transaction, TransactionState.CANCELLED, OWNER))
        assertEquals(
            TransactionRole.REQUESTER,
            TransactionMoves.actor(transaction, TransactionState.CANCELLED, REQUESTER),
        )
        assertEquals(
            "wrong user",
            assertFailsWith<ApiException> {
                TransactionMoves.actor(transaction, TransactionState.CANCELLED, "c".repeat(32))
            }.verbose,
        )
    }

    @Test
    fun `a move appends its action, sets the read flags by its actor and names the actor of a cancellation`() {
        val transaction: TransactionRecord = transaction(TransactionState.REQUESTED, TransactionMode.LENDING)

        val accepted: TransactionRecord = transaction.moved(TransactionState.ACCEPTED, TransactionRole.OWNER, 2)
        val cancelled: TransactionRecord = accepted.moved(TransactionState.CANCELLED, TransactionRole.REQUESTER, 3)

        assertEquals(TransactionRead(requester = false, owner = true), accepted.read)
        assertNull(accepted.actions.last().actor)
        assertEquals(TransactionAction("cancelled", 3, "requester"), cancelled.actions.last())
        assertEquals(TransactionRead(requester = true, owner = false), cancelled.read)
        assertEquals(3, cancelled.version)
    }

    private fun transaction(
        state: TransactionState,
        mode: TransactionMode,
    ): TransactionRecord =
        TransactionRecord(
            id = "d".repeat(32),
            version = 1,
            item = "e".repeat(32),
            owner = OWNER,
            requester = REQUESTER,
            mode = mode,
            state = state,
            created = 1,
            actions = listOf(TransactionAction("requested", 1)),
            read = TransactionRead.after(TransactionRole.REQUESTER),
            snapshot =
                TransactionSnapshot(
                    item = TransactionItemSnapshot(entity = "inv:x"),
                    entity = TransactionEntitySnapshot(),
                    owner = TransactionUserSnapshot("owner"),
                    requester = TransactionUserSnapshot("requester"),
                ),
        )

    private companion object {
        val OWNER: String = "a".repeat(32)
        val REQUESTER: String = "b".repeat(32)
    }
}
