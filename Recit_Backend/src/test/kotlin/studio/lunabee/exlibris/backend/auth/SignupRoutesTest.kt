package studio.lunabee.exlibris.backend.auth

import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SignupRoutesTest {
    @Test
    fun `signing up answers ok, opens a session naming the new user and mails the confirmation`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()

            val response = client.signup(account)

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
            val cookies: Map<String, String> = response.setCookies()
            val userId: String? = sessionUser(cookies)
            assertNotNull(userId)
            assertTrue(cookies.containsKey("inventaire:session.sig"))
            val me: String = client.get("/api/user") { sendCookies(cookies) }.bodyAsText()
            assertTrue(me.contains(""""_id":"$userId""""))
            val mail: String = AuthTestEnvironment.mailsTo(account.email).single()
            assertTrue(mail.contains("http://localhost:8080/confirm-email?token="))
        }

    @Test
    fun `a taken username is refused, whatever its case`() =
        authTest {
            val taken: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(taken)

            val response = client.signup(AuthTestEnvironment.newAccount().copy(username = taken.username.uppercase()))

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/username-availability.taken.json", response.bodyAsText())
        }

    @Test
    fun `a taken address is refused, whatever its case`() =
        authTest {
            val taken: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(taken)

            val response = client.signup(AuthTestEnvironment.newAccount().copy(email = taken.email.uppercase()))

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/signup.email-taken.derived.json", response.bodyAsText())
        }

    @Test
    fun `a one-letter username is refused as invalid_username`() =
        authTest {
            val response = client.signup(AuthTestEnvironment.newAccount().copy(username = "a"))

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/username-availability.invalid.json", response.bodyAsText())
        }

    @Test
    fun `a reserved word is refused as one`() =
        authTest {
            val response = client.signup(AuthTestEnvironment.newAccount().copy(username = "profile"))

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/username-availability.reserved.json", response.bodyAsText())
        }

    @Test
    fun `a malformed address is refused as invalid_email`() =
        authTest {
            val response = client.signup(AuthTestEnvironment.newAccount().copy(email = "not-an-email"))

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/email-availability.invalid.json", response.bodyAsText())
        }

    @Test
    fun `a seven-character password is refused as invalid_password, without echoing it`() =
        authTest {
            val response = client.signup(AuthTestEnvironment.newAccount(), password = "1234567")

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/signup.invalid-password.derived.json", response.bodyAsText())
        }

    @Test
    fun `a sixth signup in an hour from one IP is refused with 429`() =
        authTest {
            repeat(5) { assertEquals(HttpStatusCode.OK, client.signup(AuthTestEnvironment.newAccount()).status) }

            val response = client.signup(AuthTestEnvironment.newAccount())

            assertEquals(HttpStatusCode.TooManyRequests, response.status)
        }
}
