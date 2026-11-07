package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.or
import studio.lunabee.exlibris.backend.items.TransactionMode
import studio.lunabee.exlibris.backend.transactions.TransactionState

/** `V7__transactions.sql`: the Échanges. Read by `transactions`, and by `items` for `busy`. */
object TransactionsTable : Table("transactions") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val item: Column<String> = char("item", DocumentId.LENGTH)
    val owner: Column<String> = char("owner", DocumentId.LENGTH)
    val requester: Column<String> = char("requester", DocumentId.LENGTH)
    val mode: Column<String> = text("transaction_mode")
    val state: Column<String> = text("state")
    val readOwner: Column<Boolean> = bool("read_owner")
    val readRequester: Column<Boolean> = bool("read_requester")
    val snapshotEntity: Column<String> = text("snapshot_entity")
    val snapshotDetails: Column<String?> = text("snapshot_details").nullable()
    val snapshotTitle: Column<String?> = text("snapshot_title").nullable()
    val snapshotImage: Column<String?> = text("snapshot_image").nullable()
    val snapshotAuthors: Column<String?> = text("snapshot_authors").nullable()
    val ownerUsername: Column<String> = text("owner_username")
    val ownerPicture: Column<String?> = text("owner_picture").nullable()
    val requesterUsername: Column<String> = text("requester_username")
    val requesterPicture: Column<String?> = text("requester_picture").nullable()
    val created: Column<Long> = long("created")

    override val primaryKey: PrimaryKey = PrimaryKey(id)

    /**
     * An Échange that keeps its book `busy`: inventaire.io's `byBusyItem` view, whose last action is `accepted`, or
     * `confirmed` on a loan.
     */
    fun holdsItem(): Op<Boolean> =
        (state eq TransactionState.ACCEPTED.storedName) or
            ((mode eq TransactionMode.LENDING.storedName) and (state eq TransactionState.CONFIRMED.storedName))
}
