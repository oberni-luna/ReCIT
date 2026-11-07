package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V3__profiles_and_relations.sql`: one switch of a user's `settings`, by its path under it. */
object UserSettingsTable : Table("user_settings") {
    val userId: Column<String> = char("user_id", DocumentId.LENGTH)
    val name: Column<String> = text("name")
    val enabled: Column<Boolean> = bool("enabled")

    override val primaryKey: PrimaryKey = PrimaryKey(userId, name)
}
