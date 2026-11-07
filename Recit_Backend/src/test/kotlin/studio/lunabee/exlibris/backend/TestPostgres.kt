package studio.lunabee.exlibris.backend

import io.ktor.server.config.ApplicationConfig
import io.ktor.server.config.MapApplicationConfig
import org.testcontainers.postgresql.PostgreSQLContainer

/** The image Compose runs, so a migration that passes here passes there. */
object TestPostgres {
    fun container(): PostgreSQLContainer = PostgreSQLContainer("postgres:17")

    /**
     * What `module()` reads, pointed at [container] and, when given, at [mailpit]. No `ktor.application.modules`:
     * nothing loads twice.
     */
    fun config(
        container: PostgreSQLContainer,
        mailpit: TestMailpit? = null,
    ): ApplicationConfig =
        MapApplicationConfig(
            "database.url" to container.jdbcUrl,
            "database.user" to container.username,
            "database.password" to container.password,
            "public.baseUrl" to "http://localhost:8080",
            "session.secrets" to "test-secret-new,test-secret-old",
            "mail.host" to (mailpit?.host ?: "localhost"),
            "mail.port" to (mailpit?.smtpPort ?: 1025).toString(),
            "mail.startTls" to "false",
            "mail.from" to "Ex-libris <no-reply@exlibris.test>",
        )
}
