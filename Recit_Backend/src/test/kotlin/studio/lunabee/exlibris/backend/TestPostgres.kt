package studio.lunabee.exlibris.backend

import io.ktor.server.config.ApplicationConfig
import io.ktor.server.config.MapApplicationConfig
import org.testcontainers.postgresql.PostgreSQLContainer

/** The image Compose runs, so a migration that passes here passes there. */
object TestPostgres {
    fun container(): PostgreSQLContainer = PostgreSQLContainer("postgres:17")

    /** What `module()` reads, pointed at [container]. No `ktor.application.modules`: nothing loads twice. */
    fun config(container: PostgreSQLContainer): ApplicationConfig =
        MapApplicationConfig(
            "database.url" to container.jdbcUrl,
            "database.user" to container.username,
            "database.password" to container.password,
        )
}
