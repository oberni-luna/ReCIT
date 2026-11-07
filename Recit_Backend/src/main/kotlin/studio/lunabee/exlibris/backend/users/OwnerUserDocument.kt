package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/**
 * `GET /api/user`, inventaire.io's `ownerSafeData`. The fields it fills in when a document lacks them — no
 * roles, no OAuth, settings with empty notifications — are filled in the same way; an attribute never set is
 * left out, as CouchDB leaves it out of the document.
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
    val bio: String? = null,
    val email: String,
    val fediversable: Boolean? = null,
    val language: String,
    val picture: String? = null,
    val position: List<Double>? = null,
    val validEmail: Boolean,
    val roles: List<String> = emptyList(),
    val settings: JsonObject,
    val snapshot: UserSnapshot,
    val summaryPeriodicity: Int? = null,
    val enabledOAuth: List<String> = emptyList(),
    val accessLevels: List<String> = emptyList(),
)
