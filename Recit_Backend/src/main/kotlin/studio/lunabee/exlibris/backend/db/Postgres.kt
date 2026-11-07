package studio.lunabee.exlibris.backend.db

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.flywaydb.core.Flyway
import javax.sql.DataSource

object Postgres {
    // Short enough for `/health` to answer while Compose's healthcheck is still waiting.
    private const val CONNECTION_TIMEOUT_MILLIS: Long = 2_000
    private const val VALIDATION_TIMEOUT_MILLIS: Long = 1_000

    fun dataSource(config: PostgresConfig): HikariDataSource =
        HikariDataSource(
            HikariConfig().apply {
                jdbcUrl = config.url
                username = config.user
                password = config.password
                connectionTimeout = CONNECTION_TIMEOUT_MILLIS
                validationTimeout = VALIDATION_TIMEOUT_MILLIS
            },
        )

    /** Replays `src/main/resources/db/migration/` up to the latest version. */
    fun migrate(dataSource: DataSource) {
        Flyway
            .configure()
            .dataSource(dataSource)
            .load()
            .migrate()
    }
}
