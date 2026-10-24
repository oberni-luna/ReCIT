package studio.lunabee.nouveaurecit.data.groups

import kotlinx.serialization.Serializable

/**
 * `GroupMembership`: one person's place in a group, as inventaire.io stores it — who, who brought
 * them in, and since when. Every one of a group's five role lists is a list of these.
 *
 * [invitor] is `null` for the creator and for a request: the server writes `null` there.
 */
@Serializable
data class GroupMembership(
    val user: String,
    val invitor: String? = null,
    val timestamp: Double? = null,
)
