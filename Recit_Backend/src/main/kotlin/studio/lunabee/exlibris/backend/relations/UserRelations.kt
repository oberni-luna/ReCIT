package studio.lunabee.exlibris.backend.relations

import kotlinx.serialization.Serializable

/**
 * `GET /api/relations`. [network] is inventaire.io's `getNetworkIds`: friends, then the people the caller shares a
 * group with, which groups (#72) add.
 */
@Serializable
data class UserRelations(
    val friends: List<String>,
    val userRequested: List<String>,
    val otherRequested: List<String>,
    val network: List<String>,
)
