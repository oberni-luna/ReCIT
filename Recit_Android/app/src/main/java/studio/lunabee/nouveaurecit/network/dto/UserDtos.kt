package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ItemCountDto(
    @SerialName("items:count") val itemsCount: Int = 0,
    @SerialName("items:last-add") val itemsLastAdd: Double? = null,
)

@Serializable
data class UserDto(
    @SerialName("_id") val id: String,
    @SerialName("_rev") val rev: String? = null,
    val username: String,
    val email: String? = null,
    val position: List<Double>? = null,
    val picture: String? = null,
    val language: String? = null,
    val snapshot: Map<String, ItemCountDto>? = null,
    val created: Double? = null,
    val bio: String? = null,
    /** Owner only (feature 0055): whether the address has been confirmed. */
    val validEmail: Boolean? = null,
    /** Owner only: visible on the fediverse. Absent until first set, and read as off by the server. */
    val fediversable: Boolean? = null,
    /** Owner only. */
    val settings: UserSettingsDto? = null,
)

/**
 * `UserSettingsDTO`: the `settings` object of `GET /api/user`, as inventaire.io stores it — two groups of
 * booleans keyed by the names `PUT /api/user` takes after `settings.<group>.`. A key the account never
 * touched is absent, and the server reads absent as on in both groups (`notifications[label] === false`,
 * `anonymize !== false`).
 */
@Serializable
data class UserSettingsDto(
    val notifications: Map<String, Boolean>? = null,
    val contributions: Map<String, Boolean>? = null,
)

@Serializable
data class UsersDto(val users: Map<String, UserDto> = emptyMap())

@Serializable
data class UserNetworkDto(
    val friends: List<String> = emptyList(),
    val userRequested: List<String> = emptyList(),
    val otherRequested: List<String> = emptyList(),
    val network: List<String> = emptyList(),
)

@Serializable
data class UserSearchResultsDto(val results: List<UserSearchResultDto> = emptyList())

@Serializable
data class UserSearchResultDto(
    val id: String,
    val type: String? = null,
    val label: String? = null,
    val image: String? = null,
    @SerialName("_score") val score: Double? = null,
)

@Serializable
data class RelationActionPayload(val user: String)

/**
 * `GravatarDTO`: what `GET /api/images/gravatar` answers — the Gravatar address of the account's e-mail,
 * built by the server so that the address itself never leaves it.
 */
@Serializable
data class GravatarDto(val url: String)

/** `PasswordChangePayload`: the body of `PUT /api/auth/password`, under the server's hyphenated names. */
@Serializable
data class PasswordChangePayload(
    @SerialName("old-password") val currentPassword: String,
    @SerialName("new-password") val newPassword: String,
)
