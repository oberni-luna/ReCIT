package studio.lunabee.exlibris.backend.images

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import studio.lunabee.exlibris.backend.db.UsersTable

/** What the database knows about images: who points at one, and the address a Gravatar is looked up by. */
class ImagesRepository(
    private val database: Database,
) {
    /** Whether any account still has [path] as its picture: two readers who upload the same file share it. */
    suspend fun isUserPicture(path: String): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                !UsersTable
                    .selectAll()
                    .where { UsersTable.picture eq path }
                    .empty()
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
