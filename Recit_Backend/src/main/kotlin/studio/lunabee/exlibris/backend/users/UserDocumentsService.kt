package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.plugins.apiJson
import studio.lunabee.exlibris.backend.relations.RelationsService

/**
 * Readers as another reader sees them, inventaire.io's `getUsersAuthorizedDataByIds`: public fields, the `network`
 * part of the snapshot for the viewer's network, and the viewer's own document in full. `/api/users/by-ids` and a
 * group's `by-id` answer them.
 */
class UserDocumentsService(
    private val repository: UsersRepository,
    private val relations: RelationsService,
) {
    /** Each of [ids] that exists, by id. */
    suspend fun documents(
        ids: Collection<String>,
        viewerId: String?,
    ): Map<String, JsonObject> {
        val network: Set<String> = viewerId?.let { relations.networkIds(it) }.orEmpty()
        val users: List<UserRecord> = repository.findByIds(ids.distinct())
        val snapshots: Map<String, UserSnapshot> = repository.snapshots(users.map { it.id })
        return users.associate { user ->
            user.id to document(user, viewerId, network, snapshots[user.id] ?: UserSnapshot.EMPTY)
        }
    }

    private fun document(
        user: UserRecord,
        viewerId: String?,
        network: Set<String>,
        snapshot: UserSnapshot,
    ): JsonObject =
        if (user.id == viewerId) {
            apiJson.encodeToJsonElement(OwnerUserDocument.serializer(), UserDocuments.owner(user, snapshot)).jsonObject
        } else {
            apiJson
                .encodeToJsonElement(
                    PublicUserDocument.serializer(),
                    UserDocuments.public(user, user.id in network, snapshot),
                ).jsonObject
        }
}
