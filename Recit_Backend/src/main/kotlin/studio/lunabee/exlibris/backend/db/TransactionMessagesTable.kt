package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V7__transactions.sql`: the messages of the Échanges. Read by `transactions`. */
object TransactionMessagesTable : Table("transaction_messages") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val transactionId: Column<String> = char("transaction_id", DocumentId.LENGTH)
    val userId: Column<String> = char("user_id", DocumentId.LENGTH)
    val message: Column<String> = text("message")
    val created: Column<Long> = long("created")

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
