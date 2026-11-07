package studio.lunabee.exlibris.backend.transactions

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.items.ItemSnapshot
import studio.lunabee.exlibris.backend.items.SnapshotsService
import studio.lunabee.exlibris.backend.items.TransactionMode
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import java.time.Clock

/**
 * The Échanges, as inventaire.io's `controllers/transactions`: asking for a book, moving the Échange through its
 * states with their effects on the book, and cancelling a deleted account's open ones. Messages are
 * [TransactionMessagesService]'s.
 */
class TransactionsService(
    private val repository: TransactionsRepository,
    private val subjects: TransactionSubjectsRepository,
    private val snapshots: SnapshotsService,
    private val clock: Clock,
) {
    /** `GET /api/transactions`: [userId]'s Échanges, as owner or requester, finished ones included. */
    suspend fun mine(userId: String): TransactionsList =
        TransactionsList(repository.ofUser(userId).map { it.document() })

    /**
     * `request`: an Échange on a book [requesterId] may see and does not own, offered, not held by another Échange,
     * and not already asked for by them; typed as the book is offered, with its first message and a snapshot of the
     * book and both readers.
     */
    suspend fun request(
        requesterId: String,
        body: JsonBody,
    ): TransactionAnswer {
        val itemId: String = TransactionRules.itemId(body)
        val message: String = TransactionRules.message(body)
        val item: RequestedItem = subjects.requestedItem(itemId, requesterId) ?: throw ApiException.missingDocument()
        requireAllowed(requesterId, item)
        requireOffered(requesterId, item)
        val now: Long = clock.millis()
        val transaction =
            TransactionRecord(
                id = DocumentId.new(),
                version = 1,
                item = item.id,
                owner = item.owner,
                requester = requesterId,
                mode = item.mode,
                state = TransactionState.REQUESTED,
                created = now,
                actions = listOf(TransactionAction(action = TransactionState.REQUESTED.storedName, timestamp = now)),
                read = TransactionRead.after(TransactionRole.REQUESTER),
                snapshot = snapshot(item, requesterId),
            )
        repository.insert(
            transaction,
            TransactionMessage(
                id = DocumentId.new(),
                transactionId = transaction.id,
                userId = requesterId,
                message = message,
                created = now,
            ),
        )
        return TransactionAnswer(transaction.document())
    }

    /**
     * `update-state`, in inventaire.io's order: the side allowed to, the book free when accepting, a state that
     * follows. A gift or a sale confirmed moves the book to the requester.
     */
    suspend fun updateState(
        userId: String,
        body: JsonBody,
    ): StateUpdated {
        val id: String = TransactionRules.id(body)
        val state: TransactionState = TransactionRules.state(body)
        val transaction: TransactionRecord = repository.find(id) ?: throw ApiException.missingDocument()
        val actor: TransactionRole = TransactionMoves.actor(transaction, state, userId)
        if (state == TransactionState.ACCEPTED && subjects.isBusy(transaction.item)) throw TransactionRules.itemBusy()
        TransactionMoves.requirePossible(transaction, state)
        return StateUpdated(move(transaction, state, actor).document())
    }

    /**
     * Before [userId]'s account goes (#75 decision 7): their open Échanges cancelled by them, as inventaire.io's
     * `cancelAllActiveTransactions`; the finished ones stay for the other side, unless that account is gone too.
     */
    suspend fun cancelOpen(userId: String) {
        repository.ofUser(userId).filter { it.isActive }.forEach { transaction ->
            move(transaction, TransactionState.CANCELLED, requireNotNull(transaction.role(userId)))
        }
        repository.forgetUnshared(userId)
    }

    /** inventaire.io's `verifyRightToInteractWithItem` with `ownerAllowed: false`, then `checkIfItemIsBusy`. */
    private fun requireAllowed(
        requesterId: String,
        item: RequestedItem,
    ) {
        if (item.owner == requesterId || !item.isVisible) {
            throw ApiException(HttpStatusCode.Forbidden, "not allowed with this item")
        }
        if (item.isBusy) throw TransactionRules.itemBusy()
    }

    /** inventaire.io's `verifyNoExistingTransaction`, then `createTransactionDoc`'s requestable modes. */
    private suspend fun requireOffered(
        requesterId: String,
        item: RequestedItem,
    ) {
        if (repository.ofUser(requesterId, item.id).any { it.isActive }) {
            throw ApiException(HttpStatusCode.Forbidden, "user already made a request on this item")
        }
        if (item.mode == TransactionMode.INVENTORYING) {
            throw ApiException(HttpStatusCode.BadRequest, "this item can't be requested")
        }
    }

    /** inventaire.io's `snapshotData`: the book's entity and Commentaire, title, cover and authors, both readers. */
    private suspend fun snapshot(
        item: RequestedItem,
        requesterId: String,
    ): TransactionSnapshot {
        val readers: Map<String, TransactionUserSnapshot> = subjects.readers(listOf(item.owner, requesterId))
        val book: ItemSnapshot? = snapshots.snapshots(listOf(item.entity))[item.entity]
        return TransactionSnapshot(
            item = TransactionItemSnapshot(entity = item.entity, details = item.details),
            entity = TransactionEntitySnapshot(title = book?.title, image = book?.image, authors = book?.authors),
            owner = readers[item.owner] ?: throw ApiException.missingDocument(),
            requester = readers[requesterId] ?: throw ApiException.unauthorized(),
        )
    }

    /** [transaction] moved to [state] by [actor], written over the version it was read at. */
    private suspend fun move(
        transaction: TransactionRecord,
        state: TransactionState,
        actor: TransactionRole,
    ): TransactionRecord {
        val now: Long = clock.millis()
        val moved: TransactionRecord = transaction.moved(state, actor, now)
        val movesItem: Boolean = state == TransactionState.CONFIRMED && transaction.movesItemWhenConfirmed
        if (!repository.update(moved, movesItem, now)) {
            throw ApiException(HttpStatusCode.Conflict, "document update conflict")
        }
        return moved
    }
}
