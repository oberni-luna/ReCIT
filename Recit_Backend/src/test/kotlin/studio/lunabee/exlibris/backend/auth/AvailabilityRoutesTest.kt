package studio.lunabee.exlibris.backend.auth

import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import kotlin.test.Test
import kotlin.test.assertEquals

class AvailabilityRoutesTest {
    @Test
    fun `a free username is available`() =
        authTest {
            val response = client.get("/api/auth/username-availability?username=exlibris_fx_8213")

            assertEquals(HttpStatusCode.OK, response.status)
            assertEquals("""{"username":"exlibris_fx_8213","status":"available"}""", response.bodyAsText())
            assertMatchesFixture("auth/username-availability.available.json", response.bodyAsText())
        }

    @Test
    fun `a taken username is taken, in any case`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account)

            val exact = client.get("/api/auth/username-availability?username=${account.username}")
            val otherCase = client.get("/api/auth/username-availability?username=${account.username.uppercase()}")

            assertEquals(HttpStatusCode.BadRequest, exact.status)
            assertMatchesFixture("auth/username-availability.taken.json", exact.bodyAsText())
            assertMatchesFixture("auth/username-availability.taken-other-case.json", otherCase.bodyAsText())
        }

    @Test
    fun `a one-letter username and a reserved word are refused`() =
        authTest {
            assertMatchesFixture(
                "auth/username-availability.invalid.json",
                client.get("/api/auth/username-availability?username=a").bodyAsText(),
            )
            assertMatchesFixture(
                "auth/username-availability.reserved.json",
                client.get("/api/auth/username-availability?username=profile").bodyAsText(),
            )
        }

    @Test
    fun `a free address is available`() =
        authTest {
            val response = client.get("/api/auth/email-availability?email=exlibris-fixture-free-8213@example.org")

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("auth/email-availability.available.json", response.bodyAsText())
        }

    @Test
    fun `a taken address is taken, in any case`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account)

            val response = client.get("/api/auth/email-availability?email=${account.email.uppercase()}")

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/signup.email-taken.derived.json", response.bodyAsText())
        }

    @Test
    fun `a malformed or missing address is refused`() =
        authTest {
            assertMatchesFixture(
                "auth/email-availability.invalid.json",
                client.get("/api/auth/email-availability?email=not-an-email").bodyAsText(),
            )
            assertMatchesFixture(
                "auth/email-availability.missing.json",
                client.get("/api/auth/email-availability").bodyAsText(),
            )
        }
}
