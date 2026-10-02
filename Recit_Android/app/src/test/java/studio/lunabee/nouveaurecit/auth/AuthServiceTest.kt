package studio.lunabee.nouveaurecit.auth

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.auth.model.AuthException
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import java.util.Base64

private class MemoryVault : SessionVault {
    var data: ByteArray? = null
    override fun load(): ByteArray? = data
    override fun save(data: ByteArray): Boolean {
        this.data = data
        return true
    }
    override fun delete() {
        data = null
    }
}

class AuthServiceTest {
    private lateinit var server: MockWebServer
    private val userPayload: String = Base64.getUrlEncoder().withoutPadding()
        .encodeToString("""{"user":"abc","timestamp":1}""".toByteArray())

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.close()
    }

    private fun service(jar: SessionCookieJar = SessionCookieJar(), vault: SessionVault = MemoryVault()): AuthService =
        AuthService(
            sessionClient = OkHttpClient.Builder().cookieJar(jar).build(),
            publicClient = OkHttpClient(),
            jar = jar,
            vault = vault,
            baseUrl = server.url("/api").toString().trimEnd('/'),
        )

    private fun sessionResponse(): MockResponse = MockResponse.Builder()
        .code(200)
        .addHeader("Set-Cookie", "inventaire:session=$userPayload; Path=/; Max-Age=15552000")
        .addHeader("Set-Cookie", "inventaire:session.sig=sig; Path=/; Max-Age=15552000")
        .body("ok")
        .build()

    @Test
    fun login_persists_the_session_and_a_new_launch_finds_it() = runTest {
        val vault = MemoryVault()
        server.enqueue(sessionResponse())
        val first: AuthService = service(vault = vault)
        assertFalse(first.isLoggedIn())
        first.login("olive", "secret")
        assertTrue(first.isLoggedIn())

        val relaunched: AuthService = service(jar = SessionCookieJar(), vault = vault)
        assertTrue(relaunched.isLoggedIn())
        assertEquals("/api/auth/login", server.takeRequest().url.encodedPath)
    }

    @Test
    fun refused_credentials_throw_and_store_nothing() = runTest {
        val vault = MemoryVault()
        server.enqueue(MockResponse.Builder().code(401).body("""{"message":"unauthorized"}""").build())
        try {
            service(vault = vault).login("olive", "wrong")
            fail("expected a failure")
        } catch (exception: AuthException) {
            assertEquals(AuthFailure.InvalidCredentials, exception.failure)
        }
        assertEquals(null, vault.data)
    }

    @Test
    fun a_200_without_cookies_is_no_session() = runTest {
        server.enqueue(MockResponse.Builder().code(200).body("ok").build())
        try {
            service().login("olive", "secret")
            fail("expected a failure")
        } catch (exception: AuthException) {
            assertEquals(AuthFailure.NoSessionCookies, exception.failure)
        }
    }

    @Test
    fun logout_forgets_even_when_the_server_fails() = runTest {
        val vault = MemoryVault()
        server.enqueue(sessionResponse())
        server.enqueue(MockResponse.Builder().code(500).build())
        val auth: AuthService = service(vault = vault)
        auth.login("olive", "secret")
        auth.logout()
        assertFalse(auth.isLoggedIn())
        assertEquals(null, vault.data)
    }

    @Test
    fun an_anonymous_jar_session_is_not_a_user() = runTest {
        val anonymous: String = Base64.getUrlEncoder().withoutPadding().encodeToString("""{"timestamp":1}""".toByteArray())
        server.enqueue(
            MockResponse.Builder().code(401)
                .addHeader("Set-Cookie", "inventaire:session=$anonymous; Path=/; Max-Age=1000")
                .body("{}")
                .build(),
        )
        val auth: AuthService = service()
        runCatching { auth.login("olive", "wrong") }
        assertFalse(auth.isLoggedIn())
    }
}
