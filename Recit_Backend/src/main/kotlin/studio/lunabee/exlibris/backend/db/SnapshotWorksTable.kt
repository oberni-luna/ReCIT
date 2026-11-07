package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.TextColumnType

/** `V5__items_and_shelves.sql`: the works a snapshot names, and what `inventory-view` groups them by. */
object SnapshotWorksTable : Table("snapshot_works") {
    val uri: Column<String> = text("uri")
    val workUri: Column<String> = text("work_uri")
    val position: Column<Int> = integer("position")
    val authors: Column<List<String>?> = array("authors", TextColumnType()).nullable()
    val genres: Column<List<String>?> = array("genres", TextColumnType()).nullable()
    val subjects: Column<List<String>?> = array("subjects", TextColumnType()).nullable()

    override val primaryKey: PrimaryKey = PrimaryKey(uri, workUri)
}
