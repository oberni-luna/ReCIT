package studio.lunabee.exlibris.backend.auth

import kotlinx.serialization.Serializable

/** `GET /api/auth/email-availability`'s answer: `{"email":"…","status":"available"}`. */
@Serializable
data class EmailAvailability(
    val email: String,
    val status: String = "available",
)
