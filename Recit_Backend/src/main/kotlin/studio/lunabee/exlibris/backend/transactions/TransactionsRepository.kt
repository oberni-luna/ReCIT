package studio.lunabee.exlibris.backend.transactions

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.notExists
import org.jetbrains.exposed.v1.core.or
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.core.statements.InsertStatement
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.batchInsert
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import studio.lunabee.exlibris.backend.db.ItemShelvesTable
import studio.lunabee.exlibris.backend.db.ItemsTable
import studio.lunabee.exlibris.backend.db.TransactionActionsTable
import studio.lunabee.exlibris.backend.db.TransactionsTable
import studio.lunabee.exlibris.backend.db.UsersTable
import studio.lunabee.exlibris.backend.items.TransactionMode

/** The Échanges and their actions; their messages are [TransactionMessagesRepository]'s. */
class TransactionsRepository(
    private val database: Database,
) {
    /** [transaction] and its first [message], together or not at all. */
    suspend fun insert(
        transaction: TransactionRecord,
        message: TransactionMessage,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                TransactionsTable.insert { it.write(transaction) }
                insertActions(transaction.id, transaction.actions, from = 0)
                insertMessage(message)
            }
        }
    }

    suspend fun find(id: String): TransactionRecord? = records { TransactionsTable.id eq id }.singleOrNull()

    /** [userId]'s Échanges, as owner or requester, the oldest first; only those on [itemId] when there is one. */
    suspend fun ofUser(
        userId: String,
        itemId: String? = null,
    ): List<TransactionRecord> =
        records {
            val mine: Op<Boolean> = (TransactionsTable.owner eq userId) or (TransactionsTable.requester eq userId)
            if (itemId == null) mine else mine and (TransactionsTable.item eq itemId)
        }

    /**
     * Writes [moved] over the version it was moved from, and its last action. When [movesItem], the book goes to the
     * requester as inventaire.io's `changeItemDocOwner` gives it: offered for nothing, seen by them alone, its
     * Commentaire and Note privée dropped, off every étagère. `false` when another write came first.
     */
    suspend fun update(
        moved: TransactionRecord,
        movesItem: Boolean,
        now: Long,
    ): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val updated: Int =
                    TransactionsTable.update({
                        (TransactionsTable.id eq moved.id) and (TransactionsTable.version eq moved.version - 1)
                    }) {
                        it[version] = moved.version
                        it[state] = moved.state.storedName
                        it[readOwner] = moved.read.owner
                        it[readRequester] = moved.read.requester
                    }
                if (updated == 1) {
                    insertActions(moved.id, moved.actions.takeLast(1), from = moved.actions.size - 1)
                    if (movesItem) moveItem(moved, now)
                }
                updated == 1
            }
        }

    /**
     * Deletes [userId]'s Échanges whose other side's account is gone already: once both readers are gone, nobody is
     * left to read them.
     */
    suspend fun forgetUnshared(userId: String) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                TransactionsTable.deleteWhere {
                    ((owner eq userId) and isGone(requester)) or ((requester eq userId) and isGone(owner))
                }
            }
        }
    }

    private fun isGone(reader: Column<String>): Op<Boolean> =
        notExists(UsersTable.select(UsersTable.id).where { UsersTable.id eq reader })

    private fun insertActions(
        transactionId: String,
        actions: List<TransactionAction>,
        from: Int,
    ) {
        TransactionActionsTable.batchInsert(actions.withIndex()) { (index, action) ->
            this[TransactionActionsTable.transactionId] = transactionId
            this[TransactionActionsTable.position] = from + index
            this[TransactionActionsTable.action] = action.action
            this[TransactionActionsTable.doneAt] = action.timestamp
            this[TransactionActionsTable.actor] = action.actor
        }
    }

    private fun moveItem(
        confirmed: TransactionRecord,
        now: Long,
    ) {
        val moved: Int =
            ItemsTable.update({ (ItemsTable.id eq confirmed.item) and (ItemsTable.owner eq confirmed.owner) }) {
                it[version] = version + 1
                it[owner] = confirmed.requester
                it[ItemsTable.transaction] = TransactionMode.INVENTORYING.storedName
                it[visibility] = emptyList()
                it[details] = null
                it[notes] = null
                it[updated] = now
            }
        if (moved == 1) ItemShelvesTable.deleteWhere { itemId eq confirmed.item }
    }

    private suspend fun records(condition: () -> Op<Boolean>): List<TransactionRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val rows: List<ResultRow> =
                    TransactionsTable
                        .selectAll()
                        .where(condition())
                        .orderBy(TransactionsTable.created to SortOrder.ASC, TransactionsTable.id to SortOrder.ASC)
                        .toList()
                val actions: Map<String, List<TransactionAction>> =
                    TransactionActionsTable
                        .selectAll()
                        .where { TransactionActionsTable.transactionId inList rows.map { it[TransactionsTable.id] } }
                        .orderBy(TransactionActionsTable.position to SortOrder.ASC)
                        .groupBy({ it[TransactionActionsTable.transactionId] }, { it.toAction() })
                rows.map { it.toTransactionRecord(actions[it[TransactionsTable.id]].orEmpty()) }
            }
        }
}

private fun InsertStatement<Number>.write(transaction: TransactionRecord) {
    this[TransactionsTable.id] = transaction.id
    this[TransactionsTable.version] = transaction.version
    this[TransactionsTable.item] = transaction.item
    this[TransactionsTable.owner] = transaction.owner
    this[TransactionsTable.requester] = transaction.requester
    this[TransactionsTable.mode] = transaction.mode.storedName
    this[TransactionsTable.state] = transaction.state.storedName
    this[TransactionsTable.readOwner] = transaction.read.owner
    this[TransactionsTable.readRequester] = transaction.read.requester
    this[TransactionsTable.snapshotEntity] = transaction.snapshot.item.entity
    this[TransactionsTable.snapshotDetails] = transaction.snapshot.item.details
    this[TransactionsTable.snapshotTitle] = transaction.snapshot.entity.title
    this[TransactionsTable.snapshotImage] = transaction.snapshot.entity.image
    this[TransactionsTable.snapshotAuthors] = transaction.snapshot.entity.authors
    this[TransactionsTable.ownerUsername] = transaction.snapshot.owner.username
    this[TransactionsTable.ownerPicture] = transaction.snapshot.owner.picture
    this[TransactionsTable.requesterUsername] = transaction.snapshot.requester.username
    this[TransactionsTable.requesterPicture] = transaction.snapshot.requester.picture
    this[TransactionsTable.created] = transaction.created
}

private fun ResultRow.toAction(): TransactionAction =
    TransactionAction(
        action = this[TransactionActionsTable.action],
        timestamp = this[TransactionActionsTable.doneAt],
        actor = this[TransactionActionsTable.actor],
    )

private fun ResultRow.toTransactionRecord(actions: List<TransactionAction>): TransactionRecord =
    TransactionRecord(
        id = this[TransactionsTable.id],
        version = this[TransactionsTable.version],
        item = this[TransactionsTable.item],
        owner = this[TransactionsTable.owner],
        requester = this[TransactionsTable.requester],
        mode = requireNotNull(TransactionMode.of(this[TransactionsTable.mode])) { "unknown transaction mode" },
        state = requireNotNull(TransactionState.of(this[TransactionsTable.state])) { "unknown transaction state" },
        created = this[TransactionsTable.created],
        actions = actions,
        read =
            TransactionRead(
                requester = this[TransactionsTable.readRequester],
                owner = this[TransactionsTable.readOwner],
            ),
        snapshot =
            TransactionSnapshot(
                item =
                    TransactionItemSnapshot(
                        entity = this[TransactionsTable.snapshotEntity],
                        details = this[TransactionsTable.snapshotDetails],
                    ),
                entity =
                    TransactionEntitySnapshot(
                        title = this[TransactionsTable.snapshotTitle],
                        image = this[TransactionsTable.snapshotImage],
                        authors = this[TransactionsTable.snapshotAuthors],
                    ),
                owner =
                    TransactionUserSnapshot(
                        username = this[TransactionsTable.ownerUsername],
                        picture = this[TransactionsTable.ownerPicture],
                    ),
                requester =
                    TransactionUserSnapshot(
                        username = this[TransactionsTable.requesterUsername],
                        picture = this[TransactionsTable.requesterPicture],
                    ),
            ),
    )
