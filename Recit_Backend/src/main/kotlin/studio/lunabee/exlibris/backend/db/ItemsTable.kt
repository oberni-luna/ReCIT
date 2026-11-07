package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.TextColumnType

/** `V5__items_and_shelves.sql`: the books. Read by `items`, `shelves` and `users` (the snapshot's counts). */
object ItemsTable : Table("items") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val owner: Column<String> = char("owner", DocumentId.LENGTH)
    val entity: Column<String> = text("entity")
    val transaction: Column<String> = text("transaction_mode")
    val visibility: Column<List<String>> = array("visibility", TextColumnType())
    val details: Column<String?> = text("details").nullable()
    val notes: Column<String?> = text("notes").nullable()
    val previousEntities: Column<List<String>?> = array("previous_entities", TextColumnType()).nullable()
    val created: Column<Long> = long("created")
    val updated: Column<Long?> = long("updated").nullable()

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
