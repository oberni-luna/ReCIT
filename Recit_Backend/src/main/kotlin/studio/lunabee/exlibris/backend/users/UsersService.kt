package studio.lunabee.exlibris.backend.users

import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.groups.GroupMembershipService
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.ParameterPlace
import studio.lunabee.exlibris.backend.transactions.TransactionsService

/** Reading an account — one's own, other readers' — and deleting it. Changing it is [UserUpdateService]'s. */
class UsersService(
    private val repository: UsersRepository,
    private val documents: UserDocumentsService,
    private val groups: GroupMembershipService,
    private val transactions: TransactionsService,
    private val images: ImagesService,
) {
    /** The signed-in user's own document. A session naming an account that is gone is refused like no session. */
    suspend fun ownerDocument(userId: String): OwnerUserDocument {
        val user: UserRecord = repository.findById(userId) ?: throw ApiException.unauthorized()
        return UserDocuments.owner(user, repository.snapshots(listOf(userId))[userId] ?: UserSnapshot.EMPTY)
    }

    /**
     * `/api/users/by-ids?ids=a|b`, public: each reader's public fields, the `network` part of the snapshot for the
     * caller's network, and the caller's own document in full, as inventaire.io's `omitPrivateData` answers.
     */
    suspend fun byIds(
        idsParameter: String,
        viewerId: String?,
    ): UsersByIds {
        val ids: List<String> = idsParameter.split('|').filter { it.isNotEmpty() }
        if (ids.isEmpty()) throw ApiException.missingParameter(ParameterPlace.QUERY, "ids")
        ids.firstOrNull { !DocumentId.isValid(it) }?.let { throw ApiException.invalidParameter("id", it) }
        return UsersByIds(documents.documents(ids, viewerId))
    }

    /**
     * `DELETE /api/user`: the account leaves its groups as inventaire.io's `leaveAllGroups` has it leave them, cancels
     * its open Échanges as `cancelAllActiveTransactions` does — before its books go, as inventaire.io orders it —, then
     * goes with its settings, links, relations, books, étagères, lists and their elements (`ON DELETE CASCADE`), then
     * its picture unless another account shares the file. Its Échanges and their messages stay for the other side. The
     * snapshots its books used are left for the nightly job to drop. The username is free again: inventaire.io keeps
     * a deleted user's, this backend keeps nothing.
     */
    suspend fun deleteAccount(userId: String) {
        val user: UserRecord = repository.findById(userId) ?: throw ApiException.unauthorized()
        groups.leaveAll(userId)
        transactions.cancelOpen(userId)
        repository.delete(userId)
        user.picture?.let { images.releasePicture(it) }
    }
}
