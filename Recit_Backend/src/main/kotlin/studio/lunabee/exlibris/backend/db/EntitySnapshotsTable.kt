package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table
import org.jetbrains.exposed.v1.core.TextColumnType

/** `V5__items_and_shelves.sql`: one entity's item snapshot, read from inventaire.io. Read by `items` and `shelves`. */
object EntitySnapshotsTable : Table("entity_snapshots") {
    val uri: Column<String> = text("uri")
    val title: Column<String> = text("title")
    val subtitle: Column<String?> = text("subtitle").nullable()
    val lang: Column<String?> = text("lang").nullable()
    val authors: Column<String?> = text("authors").nullable()
    val image: Column<String?> = text("image").nullable()
    val series: Column<String?> = text("series").nullable()
    val ordinal: Column<String?> = text("ordinal").nullable()
    val isbn13: Column<String?> = text("isbn13").nullable()
    val isbn10: Column<String?> = text("isbn10").nullable()
    val worksUris: Column<List<String>> = array("works_uris", TextColumnType())
    val authorsUris: Column<List<String>> = array("authors_uris", TextColumnType())
    val seriesUris: Column<List<String>> = array("series_uris", TextColumnType())
    val refreshed: Column<Long> = long("refreshed")

    override val primaryKey: PrimaryKey = PrimaryKey(uri)
}
