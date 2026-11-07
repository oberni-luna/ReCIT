package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V4__groups.sql`. Read by `groups`, `search` and `images`. */
object GroupsTable : Table("groups") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val name: Column<String> = text("name")
    val slug: Column<String> = text("slug")
    val description: Column<String> = text("description")
    val searchable: Column<Boolean> = bool("searchable")
    val open: Column<Boolean> = bool("open")
    val picture: Column<String?> = text("picture").nullable()
    val latitude: Column<Double?> = double("latitude").nullable()
    val longitude: Column<Double?> = double("longitude").nullable()
    val creator: Column<String> = char("creator", DocumentId.LENGTH)
    val created: Column<Long> = long("created")

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
