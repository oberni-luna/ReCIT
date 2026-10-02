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
