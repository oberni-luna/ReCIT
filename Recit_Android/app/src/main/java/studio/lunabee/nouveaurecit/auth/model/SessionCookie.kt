package studio.lunabee.nouveaurecit.auth.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.Base64

/**
 * `Model/Authentication/SessionCookie.swift`. Every public endpoint hands out an anonymous session
 * under the same cookie names; only the payload — unpadded base64url JSON — tells who it belongs to.
 */
object SessionCookie {
    sealed interface Owner {
        data class User(val id: String) : Owner
        data object Anonymous : Owner
        data object Unreadable : Owner
    }

    @Serializable
    private data class Payload(val user: String? = null)

    private val json: Json = Json { ignoreUnknownKeys = true }

    fun owner(value: String): Owner {
        val payload: Payload = try {
            val bytes: ByteArray = Base64.getUrlDecoder().decode(value.trimEnd('='))
            json.decodeFromString(Payload.serializer(), bytes.decodeToString())
        } catch (_: IllegalArgumentException) {
            return Owner.Unreadable
        }
        val user: String = payload.user?.takeIf { it.isNotEmpty() } ?: return Owner.Anonymous
        return Owner.User(user)
    }

    fun namesAUser(values: List<String>): Boolean = values.any { owner(it) is Owner.User }
}
