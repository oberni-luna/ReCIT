package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonPrimitive
import studio.lunabee.nouveaurecit.data.groups.GroupMembership

/**
 * A group document as inventaire.io serves it — `GET /api/groups`, `/api/groups/by-id`, and the
 * answer to `POST /api/groups`.
 *
 * Everything but the id, the name and the two lists every group has is optional: the server omits
 * `picture` and `description` when there are none, and older documents predate `open`.
 */
@Serializable
data class GroupDto(
    @SerialName("_id") val id: String,
    @SerialName("_rev") val rev: String? = null,
    val name: String,
    val slug: String? = null,
    val description: String? = null,
    val picture: String? = null,
    val searchable: Boolean? = null,
    val open: Boolean? = null,
    val admins: List<GroupMembership> = emptyList(),
    val members: List<GroupMembership> = emptyList(),
    val invited: List<GroupMembership>? = null,
    val declined: List<GroupMembership>? = null,
    val requested: List<GroupMembership>? = null,
)

/** `GET /api/groups`: admin, member or invited — **not** the groups I asked to join. */
@Serializable
data class GroupsDto(val groups: List<GroupDto> = emptyList())

/** `GET /api/groups/by-id`: the group, and the people it names, already shaped as users. */
@Serializable
data class GroupByIdDto(val group: GroupDto, val users: List<UserDto> = emptyList())

/**
 * `GET /api/search?types=groups`: an id, a name, sometimes a description and a picture. Nothing
 * about who is in it or whether it is open — the group's own screen reads that.
 */
@Serializable
data class GroupSearchResultsDto(val results: List<GroupSearchResultDto> = emptyList())

@Serializable
data class GroupSearchResultDto(
    val id: String,
    val label: String = "",
    val description: String? = null,
    val image: String? = null,
    @SerialName("_score") val score: Double? = null,
)

/** The body of every `PUT /api/groups/<action>`: the group, and the other person when the gesture is about someone else. */
@Serializable
data class GroupActionPayload(val group: String, val user: String? = null)

/** The body of `POST /api/groups`. `position` exists on the server and is not offered yet. */
@Serializable
data class GroupCreationPayload(
    val name: String,
    val description: String,
    val searchable: Boolean,
    val open: Boolean,
)

/** The body of `PUT /api/groups/update-settings`: one attribute and its new value per call. */
@Serializable
data class GroupSettingPayload(val group: String, val attribute: String, val value: JsonPrimitive)
