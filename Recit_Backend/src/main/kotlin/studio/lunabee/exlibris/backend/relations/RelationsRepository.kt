package studio.lunabee.exlibris.backend.relations

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.or
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.insertIgnore
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import studio.lunabee.exlibris.backend.db.RelationsTable
import studio.lunabee.exlibris.backend.db.UsersTable

class RelationsRepository(
    private val database: Database,
) {
    suspend fun userExists(userId: String): Boolean =
        withContext(Dispatchers.IO) {
            transaction(database) {
                !UsersTable
                    .selectAll()
                    .where { UsersTable.id eq userId }
                    .empty()
            }
        }

    /** Every pair [userId] is in, by the other's id. */
    suspend fun statusesOf(userId: String): Map<String, RelationStatus> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                RelationsTable
                    .selectAll()
                    .where { (RelationsTable.userA eq userId) or (RelationsTable.userB eq userId) }
                    .associate { row ->
                        val pair: List<String> = listOf(row[RelationsTable.userA], row[RelationsTable.userB])
                        pair.single { it != userId } to RelationStatus.of(row[RelationsTable.status])
                    }
            }
        }

    /**
     * Moves the pair to where [next] says [userId] stands, from where they stood, the row locked meanwhile: two
     * readers asking each other at once end as friends, never as two requests. [next] answering `null` changes
     * nothing. A pair never met is created only when [next] has something to say from `none`.
     */
    suspend fun transition(
        userId: String,
        otherId: String,
        now: Long,
        next: (UserRelation) -> UserRelation?,
    ) {
        val (userA: String, userB: String) = if (userId < otherId) userId to otherId else otherId to userId
        withContext(Dispatchers.IO) {
            transaction(database) {
                if (next(UserRelation.NONE) != null) {
                    RelationsTable.insertIgnore {
                        it[RelationsTable.userA] = userA
                        it[RelationsTable.userB] = userB
                        it[status] = RelationStatus.NONE.storedName
                        it[created] = now
                        it[updated] = now
                    }
                }
                val pair = (RelationsTable.userA eq userA) and (RelationsTable.userB eq userB)
                val current: RelationStatus =
                    RelationsTable
                        .selectAll()
                        .where { pair }
                        .forUpdate()
                        .singleOrNull()
                        ?.let { RelationStatus.of(it[RelationsTable.status]) }
                        ?: RelationStatus.NONE
                next(UserRelation.of(userId, otherId, current))?.let { relation ->
                    RelationsTable.update({ pair }) {
                        it[status] = relation.status(userId, otherId).storedName
                        it[updated] = now
                    }
                }
            }
        }
    }
}
