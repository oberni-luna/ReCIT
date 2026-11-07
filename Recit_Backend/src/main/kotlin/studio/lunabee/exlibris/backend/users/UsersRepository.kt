package studio.lunabee.exlibris.backend.users

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Count
import org.jetbrains.exposed.v1.core.Max
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.count
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.inList
import org.jetbrains.exposed.v1.core.lowerCase
import org.jetbrains.exposed.v1.core.max
import org.jetbrains.exposed.v1.core.neq
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.core.statements.UpdateStatement
import org.jetbrains.exposed.v1.core.stringParam
import org.jetbrains.exposed.v1.exceptions.ExposedSQLException
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import org.jetbrains.exposed.v1.jdbc.upsert
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.db.ItemsTable
import studio.lunabee.exlibris.backend.db.UserSettingsTable
import studio.lunabee.exlibris.backend.db.UsersTable

class UsersRepository(
    private val database: Database,
) {
    suspend fun findById(id: String): UserRecord? = findByIds(listOf(id)).singleOrNull()

    suspend fun findByIds(ids: Collection<String>): List<UserRecord> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val settings: Map<String, Map<String, Boolean>> =
                    UserSettingsTable
                        .selectAll()
                        .where { UserSettingsTable.userId inList ids }
                        .groupBy(
                            { it[UserSettingsTable.userId] },
                            { it[UserSettingsTable.name] to it[UserSettingsTable.enabled] },
                        ).mapValues { (_, switches) -> switches.toMap() }
                UsersTable
                    .selectAll()
                    .where { UsersTable.id inList ids }
                    .map { it.toUserRecord(settings[it[UsersTable.id]].orEmpty()) }
            }
        }

    /** Each of [ownerIds]' `snapshot`, computed from their books as inventaire.io's `updateSnapshotItemsCounts`. */
    suspend fun snapshots(ownerIds: Collection<String>): Map<String, UserSnapshot> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val count: Count = ItemsTable.id.count()
                val lastAdd: Max<Long, Long> = ItemsTable.created.max()
                ItemsTable
                    .select(ItemsTable.owner, ItemsTable.visibility, count, lastAdd)
                    .where { ItemsTable.owner inList ownerIds }
                    .groupBy(ItemsTable.owner, ItemsTable.visibility)
                    .groupBy({ it[ItemsTable.owner] }, {
                        it[ItemsTable.visibility] to
                            ItemCount(it[count].toInt(), it[lastAdd])
                    })
                    .mapValues { (_, counts) -> UserSnapshot.of(counts.toMap()) }
            }
        }

    /** Whether another account than [exceptId] holds [username], without regard to case, as the unique index. */
    suspend fun isUsernameTaken(
        username: String,
        exceptId: String,
    ): Boolean = isTaken(exceptId) { UsersTable.username.lowerCase() eq stringParam(username).lowerCase() }

    suspend fun isEmailTaken(
        email: String,
        exceptId: String,
    ): Boolean = isTaken(exceptId) { UsersTable.email.lowerCase() eq stringParam(email).lowerCase() }

    /**
     * Writes [update] and moves the document's revision. `false` when the username or the address was taken in the
     * meantime: the unique indexes said no.
     */
    suspend fun apply(
        userId: String,
        update: ProfileUpdate,
    ): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) {
                    if (update is ProfileUpdate.Setting) {
                        UserSettingsTable.upsert {
                            it[UserSettingsTable.userId] = userId
                            it[name] = update.name
                            it[enabled] = update.isEnabled
                        }
                    }
                    UsersTable.update({ UsersTable.id eq userId }) {
                        it[version] = version + 1
                        it.write(update)
                    }
                }
                true
            } catch (error: ExposedSQLException) {
                if (error.sqlState != UNIQUE_VIOLATION) throw error
                logger.info("A profile update lost a race on a unique index: {}", error.message)
                false
            }
        }

    /** Its settings, links and relations go with it (`ON DELETE CASCADE`). */
    suspend fun delete(userId: String) {
        withContext(Dispatchers.IO) {
            transaction(database) { UsersTable.deleteWhere { id eq userId } }
        }
    }

    private suspend fun isTaken(
        exceptId: String,
        condition: () -> Op<Boolean>,
    ): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                !UsersTable
                    .selectAll()
                    .where { condition() and (UsersTable.id neq exceptId) }
                    .empty()
            }
        }

    private companion object {
        /** Postgres's `unique_violation`. */
        const val UNIQUE_VIOLATION: String = "23505"

        val logger: Logger = LoggerFactory.getLogger(UsersRepository::class.java)
    }
}

private fun UpdateStatement.write(update: ProfileUpdate) {
    when (update) {
        is ProfileUpdate.Username -> {
            this[UsersTable.username] = update.value
        }

        is ProfileUpdate.Email -> {
            this[UsersTable.email] = update.value
            this[UsersTable.emailValidated] = false
        }

        is ProfileUpdate.Language -> {
            this[UsersTable.language] = update.value
        }

        is ProfileUpdate.Bio -> {
            this[UsersTable.bio] = update.value
        }

        is ProfileUpdate.Picture -> {
            this[UsersTable.picture] = update.path
        }

        is ProfileUpdate.Position -> {
            this[UsersTable.latitude] = update.position?.latitude
            this[UsersTable.longitude] = update.position?.longitude
        }

        is ProfileUpdate.Fediversable -> {
            this[UsersTable.fediversable] = update.value
        }

        is ProfileUpdate.SummaryPeriodicity -> {
            this[UsersTable.summaryPeriodicity] = update.days
        }

        is ProfileUpdate.Setting -> {
            Unit
        }
    }
}

private fun ResultRow.toUserRecord(settings: Map<String, Boolean>): UserRecord {
    val latitude: Double? = this[UsersTable.latitude]
    val longitude: Double? = this[UsersTable.longitude]
    return UserRecord(
        id = this[UsersTable.id],
        version = this[UsersTable.version],
        username = this[UsersTable.username],
        email = this[UsersTable.email],
        language = this[UsersTable.language],
        isEmailValidated = this[UsersTable.emailValidated],
        created = this[UsersTable.created],
        bio = this[UsersTable.bio],
        picture = this[UsersTable.picture],
        position = if (latitude != null && longitude != null) UserPosition(latitude, longitude) else null,
        fediversable = this[UsersTable.fediversable],
        summaryPeriodicity = this[UsersTable.summaryPeriodicity],
        settings = settings,
    )
}
