package studio.lunabee.exlibris.backend.users

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import studio.lunabee.exlibris.backend.db.UsersTable

class UsersRepository(
    private val database: Database,
) {
    suspend fun findById(id: String): UserRecord? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                UsersTable
                    .selectAll()
                    .where { UsersTable.id eq id }
                    .singleOrNull()
                    ?.let { row ->
                        UserRecord(
                            id = row[UsersTable.id],
                            version = row[UsersTable.version],
                            username = row[UsersTable.username],
                            email = row[UsersTable.email],
                            language = row[UsersTable.language],
                            isEmailValidated = row[UsersTable.emailValidated],
                            created = row[UsersTable.created],
                        )
                    }
            }
        }
}
