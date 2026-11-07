package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.TextColumnType

/** `V5__items_and_shelves.sql`: the étagères. Read by `shelves` and `items`. */
object ShelvesTable : Table("shelves") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val owner: Column<String> = char("owner", DocumentId.LENGTH)
    val name: Column<String> = text("name")
    val description: Column<String> = text("description")
    val visibility: Column<List<String>> = array("visibility", TextColumnType())
    val color: Column<String?> = text("color").nullable()
    val created: Column<Long> = long("created")
    val updated: Column<Long?> = long("updated").nullable()

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
