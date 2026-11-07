package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Another reader as `/api/users/by-ids` shows them to anyone: inventaire.io's `userAttributes.public`, never an
 * address, a language or a setting.
 */
@Serializable
data class PublicUserDocument(
    @SerialName("_id")
    val id: String,
    val username: String,
    val bio: String? = null,
    val created: Long,
    val fediversable: Boolean? = null,
    val picture: String? = null,
    val position: List<Double>? = null,
    val snapshot: UserSnapshot,
)
