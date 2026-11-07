package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.TextColumnType

/** `V6__lists.sql`: the lists. Read by `lists`. */
object ListsTable : Table("lists") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val creator: Column<String> = char("creator", DocumentId.LENGTH)
    val name: Column<String> = text("name")
    val description: Column<String> = text("description")
    val visibility: Column<List<String>> = array("visibility", TextColumnType())
    val type: Column<String> = text("type")
    val created: Column<Long> = long("created")
    val updated: Column<Long?> = long("updated").nullable()

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
