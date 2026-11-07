package studio.lunabee.exlibris.backend.auth

import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Base64

/**
 * The secret an e-mailed link carries: 32 random bytes. Only its SHA-256 is stored — enough for a value that
 * random, and it lets the link alone find its account.
 */
object AccountToken {
    private const val BYTES: Int = 32

    fun generate(): String {
        val bytes: ByteArray = ByteArray(BYTES).also(SecureRandom()::nextBytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }

    fun hash(token: String): String = MessageDigest.getInstance("SHA-256").digest(token.toByteArray()).toHexString()
}
