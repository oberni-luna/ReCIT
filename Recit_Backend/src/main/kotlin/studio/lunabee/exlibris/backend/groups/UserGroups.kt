package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.Serializable

/** `GET /api/groups`: the groups where the caller is admin, member or invited — not those they asked to join. */
@Serializable
data class UserGroups(
    val groups: List<GroupDocument>,
)
