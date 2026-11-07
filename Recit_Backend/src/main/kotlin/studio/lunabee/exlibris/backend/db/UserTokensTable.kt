package studio.lunabee.exlibris.backend.db

import org.jetbrains.exposed.v1.core.Column
import org.jetbrains.exposed.v1.core.Table

/** `V2__users.sql`: the links the account e-mails carry, by the hash of their token. */
object UserTokensTable : Table("user_tokens") {
    private const val SHA256_HEX_LENGTH: Int = 64

    val tokenHash: Column<String> = char("token_hash", SHA256_HEX_LENGTH)
    val userId: Column<String> = char("user_id", DocumentId.LENGTH)
    val purpose: Column<String> = text("purpose")
    val expiresAt: Column<Long> = long("expires_at")

    override val primaryKey: PrimaryKey = PrimaryKey(tokenHash)
}
