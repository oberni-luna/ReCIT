package studio.lunabee.exlibris.backend.auth

import kotlinx.serialization.Serializable

/** `GET /api/auth/username-availability`'s answer: `{"username":"…","status":"available"}`. */
@Serializable
data class UsernameAvailability(
    val username: String,
    val status: String = "available",
)
