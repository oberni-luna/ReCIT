package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.ParameterPlace
import studio.lunabee.exlibris.backend.plugins.apiJson
import studio.lunabee.exlibris.backend.relations.RelationsService

/** Reading an account — one's own, other readers' — and deleting it. Changing it is [UserUpdateService]'s. */
class UsersService(
    private val repository: UsersRepository,
    private val relations: RelationsService,
    private val images: ImagesService,
) {
    /** The signed-in user's own document. A session naming an account that is gone is refused like no session. */
    suspend fun ownerDocument(userId: String): OwnerUserDocument {
        val user: UserRecord = repository.findById(userId) ?: throw ApiException.unauthorized()
        return UserDocuments.owner(user)
    }

    /**
     * `/api/users/by-ids?ids=a|b`, public: each reader's public fields, the `network` part of the snapshot for the
     * caller's friends, and the caller's own document in full, as inventaire.io's `omitPrivateData` answers.
     */
    suspend fun byIds(
        idsParameter: String,
        viewerId: String?,
    ): UsersByIds {
        val ids: List<String> = idsParameter.split('|').filter { it.isNotEmpty() }
        if (ids.isEmpty()) throw ApiException.missingParameter(ParameterPlace.QUERY, "ids")
        ids.firstOrNull { !DocumentId.isValid(it) }?.let { throw ApiException.invalidParameter("id", it) }
        val network: Set<String> = viewerId?.let { relations.friendIds(it) }.orEmpty()
        return UsersByIds(
            repository.findByIds(ids.distinct()).associate { user ->
                user.id to document(user, viewerId, network)
            },
        )
    }

    /**
     * `DELETE /api/user`: the account, its settings, links and relations, then its picture unless another account
     * shares the file. Groups (#72), books and étagères (#73), lists (#74) and transactions (#75) add theirs. The
     * username is free again: inventaire.io keeps a deleted user's, this backend keeps nothing.
     */
    suspend fun deleteAccount(userId: String) {
        val user: UserRecord = repository.findById(userId) ?: throw ApiException.unauthorized()
        repository.delete(userId)
        user.picture?.let { images.releaseUserPicture(it) }
    }

    private fun document(
        user: UserRecord,
        viewerId: String?,
        network: Set<String>,
    ): JsonObject =
        if (user.id == viewerId) {
            apiJson.encodeToJsonElement(OwnerUserDocument.serializer(), UserDocuments.owner(user)).jsonObject
        } else {
            apiJson
                .encodeToJsonElement(PublicUserDocument.serializer(), UserDocuments.public(user, user.id in network))
                .jsonObject
        }
}
