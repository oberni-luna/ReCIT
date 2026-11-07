package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.TextColumnType

/** `V6__lists.sql`: the lists' elements. Read by `lists`. */
object ListElementsTable : Table("list_elements") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val listId: Column<String> = char("list_id", DocumentId.LENGTH)
    val uri: Column<String> = text("uri")
    val ordinal: Column<String> = text("ordinal")
    val comment: Column<String?> = text("comment").nullable()
    val previousUris: Column<List<String>?> = array("previous_uris", TextColumnType()).nullable()
    val created: Column<Long> = long("created")
    val updated: Column<Long?> = long("updated").nullable()
    val uriChecked: Column<Long> = long("uri_checked")

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
