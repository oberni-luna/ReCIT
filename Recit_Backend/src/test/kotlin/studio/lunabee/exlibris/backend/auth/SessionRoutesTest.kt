package studio.lunabee.exlibris.backend.auth

import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SessionRoutesTest {
    @Test
    fun `a public call hands out an anonymous session, as inventaire's do`() =
        authTest {
            val response = client.get("/api/auth/username-availability?username=exlibris_fx_8213")

            val cookies: Map<String, String> = response.setCookies()
            assertNotNull(cookies["inventaire:session"])
            assertNotNull(cookies["inventaire:session.sig"])
            assertNull(sessionUser(cookies))
            assertTrue(
                response.headers
                    .getAll(HttpHeaders.SetCookie)
                    .orEmpty()
                    .all { it.contains("; samesite=lax; httponly") },
            )
        }

    @Test
    fun `a tampered signature makes the request anonymous`() =
        authTest {
            val cookies: Map<String, String> = client.signup(AuthTestEnvironment.newAccount()).setCookies()
            val tampered: Map<String, String> =
                cookies + ("inventaire:session.sig" to cookies.getValue("inventaire:session.sig").reversed())

            val response = client.get("/api/user") { sendCookies(tampered) }

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertNull(sessionUser(response.setCookies()))
        }

    @Test
    fun `signing out expires both cookies and sends the client to the landing page`() =
        authTest {
            val noRedirects = createClient { followRedirects = false }
            val cookies: Map<String, String> = client.signup(AuthTestEnvironment.newAccount()).setCookies()

            val response = noRedirects.post("/api/auth/logout") { sendCookies(cookies) }

            assertEquals(HttpStatusCode.Found, response.status)
            assertEquals("/", response.headers[HttpHeaders.Location])
            val setCookies: List<String> = response.headers.getAll(HttpHeaders.SetCookie).orEmpty()
            assertEquals(2, setCookies.count { it.contains("expires=Thu, 01 Jan 1970 00:00:00 GMT") })
            assertEquals(emptyMap(), response.setCookies())
            assertEquals(
                HttpStatusCode.Unauthorized,
                client.get("/api/user") { sendCookies(response.setCookies()) }.status,
            )
        }
}
