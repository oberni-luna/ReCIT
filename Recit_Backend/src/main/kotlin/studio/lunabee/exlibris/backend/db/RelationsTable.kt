package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V3__profiles_and_relations.sql`: one row per pair of readers, [userA] the smaller id. */
object RelationsTable : Table("relations") {
    val userA: Column<String> = char("user_a", DocumentId.LENGTH)
    val userB: Column<String> = char("user_b", DocumentId.LENGTH)
    val status: Column<String> = text("status")
    val created: Column<Long> = long("created")
    val updated: Column<Long> = long("updated")

    override val primaryKey: PrimaryKey = PrimaryKey(userA, userB)
}
