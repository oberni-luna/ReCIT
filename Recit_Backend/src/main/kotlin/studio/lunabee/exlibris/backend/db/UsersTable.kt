package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V2__users.sql`, the profile from `V3__profiles_and_relations.sql`. Read by `auth`, `users`, `search`. */
object UsersTable : Table("users") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val username: Column<String> = text("username")
    val email: Column<String> = text("email")
    val passwordHash: Column<String> = text("password_hash")
    val language: Column<String> = text("language")
    val emailValidated: Column<Boolean> = bool("email_validated")
    val created: Column<Long> = long("created")
    val bio: Column<String?> = text("bio").nullable()
    val picture: Column<String?> = text("picture").nullable()
    val latitude: Column<Double?> = double("latitude").nullable()
    val longitude: Column<Double?> = double("longitude").nullable()
    val fediversable: Column<Boolean?> = bool("fediversable").nullable()
    val summaryPeriodicity: Column<Int?> = integer("summary_periodicity").nullable()

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
