package studio.lunabee.exlibris.backend

import com.zaxxer.hikari.HikariDataSource
import org.jetbrains.exposed.v1.core.DatabaseConfig
import org.jetbrains.exposed.v1.jdbc.Database
import studio.lunabee.exlibris.backend.db.Postgres
import studio.lunabee.exlibris.backend.db.PostgresConfig
import studio.lunabee.exlibris.backend.health.HealthRepository
import studio.lunabee.exlibris.backend.health.HealthService

/**
 * The composition root, as `Recit_Android`'s `AppContainer`: repositories, then services, built by hand
 * once per process and read by [module]. Nothing else constructs a repository or a service.
 */
class AppContainer(
    config: PostgresConfig,
) : AutoCloseable {
    private val dataSource: HikariDataSource = Postgres.dataSource(config)

    // One attempt per transaction: a database that is down must say so at once, not after retries.
    private val database: Database =
        Database.connect(
            datasource = dataSource,
            databaseConfig = DatabaseConfig { defaultMaxAttempts = 1 },
        )

    val healthService: HealthService = HealthService(HealthRepository(database))

    fun migrate() {
        Postgres.migrate(dataSource)
    }

    override fun close() {
        dataSource.close()
    }
}
