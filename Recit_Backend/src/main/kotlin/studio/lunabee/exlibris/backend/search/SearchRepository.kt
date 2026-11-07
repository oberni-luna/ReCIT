package studio.lunabee.exlibris.backend.search

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.CustomFunction
import org.jetbrains.exposed.v1.core.Expression
import org.jetbrains.exposed.v1.core.FloatColumnType
import org.jetbrains.exposed.v1.core.SortOrder
import org.jetbrains.exposed.v1.core.greater
import org.jetbrains.exposed.v1.core.like
import org.jetbrains.exposed.v1.core.lowerCase
import org.jetbrains.exposed.v1.core.or
import org.jetbrains.exposed.v1.core.stringParam
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.select
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import studio.lunabee.exlibris.backend.db.UsersTable

class SearchRepository(
    private val database: Database,
) {
    /**
     * The readers whose username holds [term] or resembles it (`pg_trgm`'s `similarity` above its default
     * threshold), the closest first, both without regard to case. The substring keeps a short search finding a
     * long name that trigrams alone would find too different.
     */
    suspend fun readers(
        term: String,
        limit: Int,
    ): List<ReaderMatch> =
        withContext(Dispatchers.IO) {
            transaction(database) {
                val name: Expression<String> = UsersTable.username.lowerCase()
                val similarity: CustomFunction<Float> =
                    CustomFunction("similarity", FloatColumnType(), name, stringParam(term.lowercase()))
                UsersTable
                    .select(UsersTable.id, UsersTable.username, UsersTable.bio, UsersTable.picture, similarity)
                    .where {
                        (name like "%${escapeLike(term.lowercase())}%") or
                            (similarity greater SIMILARITY_THRESHOLD)
                    }.orderBy(similarity to SortOrder.DESC, name to SortOrder.ASC)
                    .limit(limit)
                    .map { row ->
                        ReaderMatch(
                            id = row[UsersTable.id],
                            username = row[UsersTable.username],
                            bio = row[UsersTable.bio],
                            picture = row[UsersTable.picture],
                            similarity = row[similarity].toDouble(),
                        )
                    }
            }
        }

    private companion object {
        /** `pg_trgm.similarity_threshold`'s default. */
        const val SIMILARITY_THRESHOLD: Float = 0.3f

        /** A username may hold `_`, which `LIKE` would read as any character. */
        fun escapeLike(term: String): String =
            term
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_")
    }
}
