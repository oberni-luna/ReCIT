package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * A group as inventaire.io serves it, from `GET /api/groups`, `by-id` and `POST /api/groups`. [picture] is left out
 * when there is none; [position] is written `null`, as inventaire.io does, hence a `JsonElement`.
 */
@Serializable
data class GroupDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val type: String,
    val name: String,
    val slug: String,
    val description: String,
    val searchable: Boolean,
    val open: Boolean,
    val picture: String? = null,
    val position: JsonElement,
    val creator: String,
    val created: Long,
    val admins: List<GroupMembershipDocument>,
    val members: List<GroupMembershipDocument>,
    val invited: List<GroupMembershipDocument>,
    val declined: List<GroupMembershipDocument>,
    val requested: List<GroupMembershipDocument>,
)
