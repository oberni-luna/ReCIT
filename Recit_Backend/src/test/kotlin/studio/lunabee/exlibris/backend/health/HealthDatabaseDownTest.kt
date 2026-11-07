package studio.lunabee.exlibris.backend.health

import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import org.testcontainers.postgresql.PostgreSQLContainer
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.module
import kotlin.test.Test
import kotlin.test.assertEquals

class HealthDatabaseDownTest {
    private val postgres: PostgreSQLContainer = TestPostgres.container()

    @Test
    fun `health answers 503 in inventaire's error shape once the database stops`() =
        testApplication {
            postgres.start()
            environment { config = TestPostgres.config(postgres) }
            application { module() }
            startApplication()

            postgres.stop()
            val response = client.get("/health")

            assertEquals(HttpStatusCode.ServiceUnavailable, response.status)
            assertEquals(
                """{"status":503,"status_verbose":"database unreachable","message":"database unreachable"}""",
                response.bodyAsText(),
            )
        }
}
