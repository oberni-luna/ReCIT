package studio.lunabee.exlibris.backend.entities

import io.ktor.server.testing.ApplicationTestBuilder
import io.ktor.server.testing.testApplication
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.module

/** The `User-Agent` decision 2 asks for, whatever the build's version. */
val exLibrisUserAgent: Regex = Regex("""^Ex-libris/\d+\.\d+\.\d+ \(\+https://github\.com/oberni-luna/ReCIT\)$""")

/** The real wiring on the auth tests' Postgres and Mailpit, relaying to [stub]. */
fun relayTest(
    stub: InventaireStub,
    block: suspend ApplicationTestBuilder.() -> Unit,
) = testApplication {
    environment {
        config = TestPostgres.config(AuthTestEnvironment.postgres, AuthTestEnvironment.mailpit, stub.baseUrl)
    }
    application { module() }
    block()
}
