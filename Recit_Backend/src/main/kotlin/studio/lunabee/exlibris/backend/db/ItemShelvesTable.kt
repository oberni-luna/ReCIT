package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V5__items_and_shelves.sql`: which étagères a book is on, in the order it was filed on them. */
object ItemShelvesTable : Table("item_shelves") {
    val itemId: Column<String> = char("item_id", DocumentId.LENGTH)
    val shelfId: Column<String> = char("shelf_id", DocumentId.LENGTH)
    val added: Column<Long> = long("added")

    override val primaryKey: PrimaryKey = PrimaryKey(itemId, shelfId)
}
