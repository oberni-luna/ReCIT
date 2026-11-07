package studio.lunabee.exlibris.backend.images

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import studio.lunabee.exlibris.backend.db.GroupsTable
import studio.lunabee.exlibris.backend.db.UsersTable

/** What the database knows about images: who points at one, and the address a Gravatar is looked up by. */
class ImagesRepository(
    private val database: Database,
) {
    /**
     * Whether any account, or any group, still has [path] as its picture, by [container]: two readers who upload the
     * same file share it.
     */
    suspend fun isPicture(
        container: ImageContainer,
        path: String,
    ): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                when (container) {
                    ImageContainer.USERS -> UsersTable.selectAll().where { UsersTable.picture eq path }
                    ImageContainer.GROUPS -> GroupsTable.selectAll().where { GroupsTable.picture eq path }
                }.empty().not()
            }
        }

    /** `null` when the account is gone. */
    suspend fun email(userId: String): String? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                UsersTable
                    .select(UsersTable.email)
                    .where { UsersTable.id eq userId }
                    .singleOrNull()
                    ?.get(UsersTable.email)
            }
        }
}
