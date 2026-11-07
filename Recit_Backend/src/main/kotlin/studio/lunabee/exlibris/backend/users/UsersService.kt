package studio.lunabee.exlibris.backend.users

import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException

class UsersService(
    private val repository: UsersRepository,
) {
    /** The signed-in user's own document. A session naming an account that is gone is refused like no session. */
    suspend fun ownerDocument(userId: String): OwnerUserDocument {
        val user: UserRecord =
            repository.findById(userId) ?: throw ApiException.unauthorized()
        return OwnerUserDocument(
            id = user.id,
            rev = DocumentId.revision(user.id, user.version),
            username = user.username,
            created = user.created,
            email = user.email,
            language = user.language,
            validEmail = user.isEmailValidated,
        )
    }
}
