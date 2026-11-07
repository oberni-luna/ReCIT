package studio.lunabee.exlibris.backend.auth

import java.security.MessageDigest
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Node's `keygrip` as inventaire.io configures it (`new Keygrip(keys, 'sha256', 'base64')`): an HMAC-SHA256
 * of the data, in base64 with `+` `/` turned into `-` `_` and the padding dropped. [secrets] are newest
 * first: the first signs, any of them verifies, so a secret can rotate without signing everybody out.
 */
class Keygrip(
    private val secrets: List<String>,
) {
    init {
        require(secrets.isNotEmpty()) { "Keygrip needs at least one secret" }
    }

    fun sign(data: String): String = sign(data, secrets.first())

    /** The position of the secret that signed [data] into [digest], or `null` when none did. */
    fun index(
        data: String,
        digest: String,
    ): Int? =
        secrets
            .indexOfFirst { secret -> MessageDigest.isEqual(sign(data, secret).toByteArray(), digest.toByteArray()) }
            .takeIf { it >= 0 }

    private fun sign(
        data: String,
        secret: String,
    ): String {
        val mac: Mac = Mac.getInstance(ALGORITHM)
        mac.init(SecretKeySpec(secret.toByteArray(), ALGORITHM))
        return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(data.toByteArray()))
    }

    private companion object {
        const val ALGORITHM: String = "HmacSHA256"
    }
}
