package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/**
 * `GET /api/groups/by-id`, inventaire.io's `getGroupPublicData`: the group, and its admins and members as
 * `/api/users/by-ids` shows them to the caller.
 */
@Serializable
data class GroupById(
    val group: GroupDocument,
    val users: List<JsonObject>,
)
