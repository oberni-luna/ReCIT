package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
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
