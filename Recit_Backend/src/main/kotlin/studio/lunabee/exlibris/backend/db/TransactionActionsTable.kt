package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V7__transactions.sql`: each Échange's `actions`. Read by `transactions`. */
object TransactionActionsTable : Table("transaction_actions") {
    val transactionId: Column<String> = char("transaction_id", DocumentId.LENGTH)
    val position: Column<Int> = integer("position")
    val action: Column<String> = text("action")
    val doneAt: Column<Long> = long("done_at")
    val actor: Column<String?> = text("actor").nullable()

    override val primaryKey: PrimaryKey = PrimaryKey(transactionId, position)
}
