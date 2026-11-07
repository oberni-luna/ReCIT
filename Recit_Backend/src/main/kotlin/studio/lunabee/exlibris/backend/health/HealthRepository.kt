package studio.lunabee.exlibris.backend.health

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import java.sql.SQLException

class HealthRepository(
    private val database: Database,
) {
    /** Asks Postgres itself, through the pool, rather than trusting the pool's own idea of it. */
    suspend fun isDatabaseReachable(): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) { exec("SELECT 1") { it.next() } } == true
            } catch (error: SQLException) {
                logger.warn("Database unreachable: {}", error.message)
                false
            }
        }

    private companion object {
        val logger: Logger = LoggerFactory.getLogger(HealthRepository::class.java)
    }
}
