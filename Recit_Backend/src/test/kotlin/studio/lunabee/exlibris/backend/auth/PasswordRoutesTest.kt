package studio.lunabee.exlibris.backend.auth

import io.ktor.client.request.get
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PasswordRoutesTest {
    @Test
    fun `the right current password changes it, and the session survives`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val cookies: Map<String, String> = client.signup(account).setCookies()

            val response =
                client.put("/api/auth/password") {
                    contentType(ContentType.Application.Json)
                    sendCookies(cookies)
                    setBody("""{"old-password":"${AuthTestEnvironment.PASSWORD}","new-password":"a new passphrase"}""")
                }

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
            assertEquals(HttpStatusCode.OK, client.get("/api/user") { sendCookies(cookies) }.status)
            assertEquals(HttpStatusCode.Unauthorized, client.login(account.username).status)
            assertEquals(HttpStatusCode.OK, client.login(account.username, password = "a new passphrase").status)
        }

    @Test
    fun `a wrong current password is refused with what PasswordChangeFailure reads`() =
        authTest {
            val cookies: Map<String, String> = client.signup(AuthTestEnvironment.newAccount()).setCookies()

            val response =
                client.put("/api/auth/password") {
                    contentType(ContentType.Application.Json)
                    sendCookies(cookies)
                    setBody("""{"old-password":"not the password","new-password":"a new passphrase"}""")
                }

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/password.wrong-current.derived.json", response.bodyAsText())
            assertTrue(response.bodyAsText().contains("old-password"))
            assertEquals(HttpStatusCode.OK, client.get("/api/user") { sendCookies(cookies) }.status)
        }

    @Test
    fun `an anonymous call cannot change a password`() =
        authTest {
            val response =
                client.put("/api/auth/password") {
                    contentType(ContentType.Application.Json)
                    setBody("""{"old-password":"whatever it is","new-password":"a new passphrase"}""")
                }

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("user/user.anonymous.json", response.bodyAsText())
        }
}
