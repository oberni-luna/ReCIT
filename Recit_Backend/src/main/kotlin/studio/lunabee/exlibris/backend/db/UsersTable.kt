package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V2__users.sql`. Read by `auth` to sign in and by `users` to answer `/api/user`. */
object UsersTable : Table("users") {
    val id: Column<String> = char("id", DocumentId.LENGTH)
    val version: Column<Int> = integer("version")
    val username: Column<String> = text("username")
    val email: Column<String> = text("email")
    val passwordHash: Column<String> = text("password_hash")
    val language: Column<String> = text("language")
    val emailValidated: Column<Boolean> = bool("email_validated")
    val created: Column<Long> = long("created")

    override val primaryKey: PrimaryKey = PrimaryKey(id)
}
