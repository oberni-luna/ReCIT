package studio.lunabee.exlibris.backend.auth

import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class EmailConfirmationRoutesTest {
    @Test
    fun `the signup link confirms the address, which api user then reports, once`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val cookies: Map<String, String> = client.signup(account).setCookies()
            val link: String = AuthTestEnvironment.mailedLink(account.email, "/confirm-email")

            val page: String = client.get(link).bodyAsText()

            assertTrue(page.contains("Address confirmed."))
            assertTrue(client.get("/api/user") { sendCookies(cookies) }.bodyAsText().contains(""""validEmail":true"""))
            assertTrue(client.get(link).bodyAsText().contains("This link no longer works."))
        }

    @Test
    fun `an account signed up in French gets the e-mail and the page in French`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account, language = "fr-FR,fr;q=0.9,en;q=0.8")
            val link: String = AuthTestEnvironment.mailedLink(account.email, "/confirm-email")

            assertEquals("Confirme ton adresse e-mail", AuthTestEnvironment.mailpit.latestSubjectTo(account.email))
            assertTrue(client.get(link).bodyAsText().contains("Adresse confirmée."))
        }

    @Test
    fun `a confirmation link opens for a day`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val userId: String? = sessionUser(client.signup(account).setCookies())
            val link: String = AuthTestEnvironment.mailedLink(account.email, "/confirm-email")
            val lifetime: Long =
                AuthTestEnvironment.queryLong(
                    "SELECT expires_at - (extract(epoch FROM now()) * 1000)::bigint FROM user_tokens " +
                        "WHERE user_id = '$userId' AND purpose = 'email_confirmation'",
                )
            assertTrue(lifetime in (ONE_DAY_MILLIS - TOLERANCE_MILLIS)..ONE_DAY_MILLIS)

            AuthTestEnvironment.execute("UPDATE user_tokens SET expires_at = 0 WHERE user_id = '$userId'")

            assertTrue(client.get(link).bodyAsText().contains("This link no longer works."))
        }

    @Test
    fun `asking again mails a new link, until the address is confirmed`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val cookies: Map<String, String> = client.signup(account).setCookies()

            val again = client.post("/api/auth/email-confirmation") { sendCookies(cookies) }

            assertEquals(HttpStatusCode.OK, again.status)
            assertMatchesFixture("auth/ok.derived.json", again.bodyAsText())
            client.get(AuthTestEnvironment.mailedLink(account.email, "/confirm-email", count = 2))
            val refused = client.post("/api/auth/email-confirmation") { sendCookies(cookies) }
            assertEquals(HttpStatusCode.BadRequest, refused.status)
            assertMatchesFixture("auth/email-confirmation.already-validated.derived.json", refused.bodyAsText())
        }

    @Test
    fun `an anonymous call cannot ask for a confirmation`() =
        authTest {
            assertEquals(HttpStatusCode.Unauthorized, client.post("/api/auth/email-confirmation").status)
        }

    private companion object {
        const val ONE_DAY_MILLIS: Long = 86_400_000
        const val TOLERANCE_MILLIS: Long = 60_000
    }
}
