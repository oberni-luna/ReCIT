package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.putJsonObject

/**
 * `GET /api/user`, inventaire.io's `ownerSafeData` for the fields #70 stores. The ones it fills in when a
 * document lacks them — no roles, no OAuth, settings with empty notifications — are filled in the same way.
 * #71 adds the profile.
 */
@Serializable
data class OwnerUserDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val type: String = "user",
    val username: String,
    val created: Long,
    val email: String,
    val language: String,
    val validEmail: Boolean,
    val roles: List<String> = emptyList(),
    val settings: JsonObject = buildJsonObject { putJsonObject("notifications") {} },
    val enabledOAuth: List<String> = emptyList(),
    val accessLevels: List<String> = emptyList(),
)
