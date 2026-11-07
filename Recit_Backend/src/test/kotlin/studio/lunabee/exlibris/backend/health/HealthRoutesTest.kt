package studio.lunabee.exlibris.backend.health

import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.testApplication
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.postgresql.PostgreSQLContainer
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.module
import kotlin.test.Test
import kotlin.test.assertEquals

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class HealthRoutesTest {
    private val postgres: PostgreSQLContainer = TestPostgres.container()

    @BeforeAll
    fun startPostgres() {
        postgres.start()
    }

    @AfterAll
    fun stopPostgres() {
        postgres.stop()
    }

    @Test
    fun `health answers ok once the database answers`() =
        testApplication {
            environment { config = TestPostgres.config(postgres) }
            application { module() }

            val response = client.get("/health")

            assertEquals(HttpStatusCode.OK, response.status)
            assertEquals("""{"status":"ok","db":"ok"}""", response.bodyAsText())
        }

    @Test
    fun `an unknown path answers 404 in inventaire's error shape`() =
        testApplication {
            environment { config = TestPostgres.config(postgres) }
            application { module() }

            val response = client.get("/api/whatever")

            assertEquals(HttpStatusCode.NotFound, response.status)
            assertEquals("""{"status":404,"status_verbose":"not found"}""", response.bodyAsText())
        }
}
