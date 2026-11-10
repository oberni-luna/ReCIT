package studio.lunabee.exlibris.backend.auth

import io.ktor.client.HttpClient
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import kotlin.test.Test
import kotlin.test.assertEquals

class LoginRoutesTest {
    @Test
    fun `the username and the password open a session naming the user`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val userId: String? = sessionUser(client.signup(account).setCookies())

            val response = client.login(account.username)

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
            assertEquals(userId, sessionUser(response.setCookies()))
        }

    @Test
    fun `the address, in any case, opens the same session`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val userId: String? = sessionUser(client.signup(account).setCookies())

            val response = client.login(account.email.uppercase())

            assertEquals(HttpStatusCode.OK, response.status)
            assertEquals(userId, sessionUser(response.setCookies()))
        }

    @Test
    fun `a wrong password answers 401, and the session stays anonymous`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account)

            val response = client.login(account.username, password = "wrong password")

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("auth/login.wrong-password.derived.json", response.bodyAsText())
            assertEquals(null, sessionUser(response.setCookies()))
        }

    @Test
    fun `an eleventh login in a minute from one IP is refused with 429`() =
        authTest {
            repeat(10) { attempt ->
                assertEquals(HttpStatusCode.Unauthorized, client.login("nobody_$attempt").status)
            }

            assertEquals(HttpStatusCode.TooManyRequests, client.login("nobody_10").status)
        }

    @Test
    fun `behind nginx, the IP counted is the last X-Forwarded-For value, the one nginx appends`() =
        authTest {
            repeat(10) { attempt ->
                val response = client.loginForwarded("nobody_xff_$attempt", "203.0.113.9, 198.51.100.1")
                assertEquals(HttpStatusCode.Unauthorized, response.status)
            }

            assertEquals(
                HttpStatusCode.TooManyRequests,
                client.loginForwarded("nobody_xff_10", "192.0.2.4, 198.51.100.1").status,
            )
            assertEquals(
                HttpStatusCode.Unauthorized,
                client.loginForwarded("nobody_xff_11", "203.0.113.9, 198.51.100.2").status,
            )
        }

    @Test
    fun `a sixth login in a minute for one username is refused with 429`() =
        authTest {
            repeat(5) { assertEquals(HttpStatusCode.Unauthorized, client.login("nobody_at_all").status) }

            assertEquals(HttpStatusCode.TooManyRequests, client.login("NOBODY_AT_ALL").status)
        }
}

private suspend fun HttpClient.loginForwarded(
    identifier: String,
    forwardedFor: String,
): HttpResponse =
    post("/api/auth/login") {
        contentType(ContentType.Application.Json)
        header(HttpHeaders.XForwardedFor, forwardedFor)
        setBody("""{"username":"$identifier","password":"${AuthTestEnvironment.PASSWORD}"}""")
    }
