package studio.lunabee.exlibris.backend.images

import kotlinx.serialization.Serializable

/** `GET /api/images/gravatar`. */
@Serializable
data class GravatarUrl(
    val url: String,
)
