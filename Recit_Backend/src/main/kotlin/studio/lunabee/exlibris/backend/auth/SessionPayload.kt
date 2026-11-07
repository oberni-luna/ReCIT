package studio.lunabee.exlibris.backend.auth

import kotlinx.serialization.Serializable

/**
 * What `inventaire:session` carries, inventaire.io's `SessionObject`: `{"user":"<id>","timestamp":<ms>}`
 * once signed in, `{"timestamp":<ms>}` for the anonymous session every public call hands out. The apps read
 * [user] to tell the two apart (`SessionCookie.swift`). [timestamp] is when the session opened: past the
 * cookie's max age, the session is closed whatever the cookie's own expiry says.
 */
@Serializable
data class SessionPayload(
    val user: String? = null,
    val timestamp: Long? = null,
)
