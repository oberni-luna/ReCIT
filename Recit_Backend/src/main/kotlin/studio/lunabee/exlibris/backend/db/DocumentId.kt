package studio.lunabee.exlibris.backend.db

import java.security.MessageDigest
import java.util.UUID

/**
 * Ids and revisions in inventaire.io's CouchDB shape (#62 decision 8): an `_id` of 32 lowercase hex
 * characters, which `isUserId` accepts, and a `_rev` of `"<version>-<hash>"` that moves on every write.
 */
object DocumentId {
    const val LENGTH: Int = 32

    private val pattern: Regex = Regex("^[0-9a-f]{$LENGTH}$")

    fun new(): String = UUID.randomUUID().toString().replace("-", "")

    /** inventaire.io's `isCouchUuid`, which every id parameter is checked against. */
    fun isValid(id: String): Boolean = pattern.matches(id)

    fun revision(
        id: String,
        version: Int,
    ): String {
        val digest: ByteArray = MessageDigest.getInstance("MD5").digest("$id:$version".toByteArray())
        return "$version-${digest.toHexString()}"
    }
}
