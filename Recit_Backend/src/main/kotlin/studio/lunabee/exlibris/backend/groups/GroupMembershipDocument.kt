package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * An entry of a group's five lists. [invitor] is a `JsonElement` because inventaire.io writes it `null`, not
 * absent, for the creator and a request, and every answer otherwise leaves a `null` out.
 */
@Serializable
data class GroupMembershipDocument(
    val user: String,
    val invitor: JsonElement,
    val timestamp: Long,
)
