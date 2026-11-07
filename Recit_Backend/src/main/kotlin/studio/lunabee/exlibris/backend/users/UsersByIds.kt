package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/** `/api/users/by-ids`: each reader found, by id, public unless it is the caller. An unknown id is left out. */
@Serializable
data class UsersByIds(
    val users: Map<String, JsonObject>,
)
