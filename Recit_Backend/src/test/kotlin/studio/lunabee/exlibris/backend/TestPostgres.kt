package studio.lunabee.exlibris.backend

import io.ktor.server.config.ApplicationConfig
import io.ktor.server.config.MapApplicationConfig
import org.testcontainers.postgresql.PostgreSQLContainer
import java.nio.file.Files
import java.nio.file.Path

/** The image Compose runs, so a migration that passes here passes there. */
object TestPostgres {
    /** One per test JVM, under the system's temporary directory: no test writes into the working tree. */
    val imagesDirectory: Path by lazy { Files.createTempDirectory("exlibris-images") }

    fun container(): PostgreSQLContainer = PostgreSQLContainer("postgres:17")

    /**
     * What `module()` reads, pointed at [container], when given at [mailpit], and at [inventaireBaseUrl]: by default
     * a port nothing listens on, never inventaire.io. No `ktor.application.modules`: nothing loads twice.
     */
    fun config(
        container: PostgreSQLContainer,
        mailpit: TestMailpit? = null,
        inventaireBaseUrl: String = "http://127.0.0.1:9",
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
            "images.directory" to imagesDirectory.toString(),
            "inventaire.baseUrl" to inventaireBaseUrl,
        )
}
