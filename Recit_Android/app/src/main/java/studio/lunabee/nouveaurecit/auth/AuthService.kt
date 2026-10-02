package studio.lunabee.nouveaurecit.auth

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import okhttp3.Cookie
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import studio.lunabee.nouveaurecit.auth.model.AuthException
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.auth.model.PasswordResetOutcome
import studio.lunabee.nouveaurecit.auth.model.PostSignupSession
import studio.lunabee.nouveaurecit.auth.model.SessionCookie
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.ErrorBodyDto
import java.io.IOException

/**
 * `Features/Authentication/Service/AuthService.swift`, and ADR 0008 with it: the one file that
 * speaks HTTP for sessions, touches the jar and touches the vault. Every decision that is not I/O
 * is a pure type under `auth/model/`.
 *
 * `sessionClient` carries [jar]; `publicClient` neither sends nor stores a cookie, and serves the
 * two availability checks and the reset — they must touch the session in neither direction.
 */
class AuthService(
    private val sessionClient: OkHttpClient,
    private val publicClient: OkHttpClient,
    private val jar: SessionCookieJar,
    private val vault: SessionVault,
    private val baseUrl: String = "${ApiService.BASE_URL}/api",
    private val clock: () -> Long = System::currentTimeMillis,
) {
    @Serializable
    private data class Credentials(val username: String, val password: String)

    @Serializable
    private data class NewAccount(val username: String, val email: String, val password: String)

    @Serializable
    private data class Address(val email: String)

    @Serializable
    private data class StoredCookie(
        val name: String,
        val value: String,
        val domain: String,
        val path: String,
        val expiresAt: Long,
        val secure: Boolean,
        val httpOnly: Boolean,
        val hostOnly: Boolean,
    )

    private val json: Json = ApiService.DefaultJson

    init {
        restoreCookiesFromVault()
        adoptJarSession()
    }

    /** The vault first; then the jar, only when its session names a user (issues 0068 / 0069). */
    fun isLoggedIn(): Boolean = isValid(persistedSessionCookies()) || jarHoldsAUserSession()

    suspend fun login(username: String, password: String) {
        val response: Pair<Int, String> = post(sessionClient, LOGIN_PATH, json.encodeToString(Credentials.serializer(), Credentials(username, password)))
            ?: throw AuthException(AuthFailure.Network)
        AuthFailure.classify(response.first, errorBody(response.second)?.message)?.let { throw AuthException(it) }
        if (!hasValidSessionCookies()) throw AuthException(AuthFailure.NoSessionCookies)
        persistCookiesToVault()
    }

    suspend fun signUp(username: String, email: String, password: String) {
        val response: Pair<Int, String> = post(
            sessionClient,
            SIGNUP_PATH,
            json.encodeToString(NewAccount.serializer(), NewAccount(username, email, password)),
        ) ?: throw AuthException(AuthFailure.Network)
        val body: ErrorBodyDto? = errorBody(response.second)
        AuthFailure.classifySignup(response.first, body?.errorName, body?.message)?.let { throw AuthException(it) }
        when (PostSignupSession.next(hasValidSessionCookies())) {
            PostSignupSession.Established -> persistCookiesToVault()
            PostSignupSession.ChainSignIn -> login(username, password)
        }
    }

    suspend fun usernameAvailability(username: String): FieldAvailability.Outcome =
        availability(USERNAME_AVAILABILITY_PATH, "username", username)

    suspend fun emailAvailability(email: String): FieldAvailability.Outcome =
        availability(EMAIL_AVAILABILITY_PATH, "email", email)

    suspend fun requestPasswordReset(email: String): PasswordResetOutcome {
        val response: Pair<Int, String> = post(publicClient, RESET_PASSWORD_PATH, json.encodeToString(Address.serializer(), Address(email)))
            ?: return PasswordResetOutcome.transportFailure
        return PasswordResetOutcome.fromServer(response.first, errorBody(response.second)?.message)
    }

    /** Tells the server, then forgets the session locally whatever the server said. */
    suspend fun logout() {
        post(sessionClient, LOGOUT_PATH, null)
        forgetSession()
    }

    fun forgetSession() {
        jar.remove(SESSION_COOKIE_NAMES)
        vault.delete()
    }

    private suspend fun availability(path: String, parameter: String, value: String): FieldAvailability.Outcome =
        withContext(Dispatchers.IO) {
            val url = "$baseUrl$path".toHttpUrl().newBuilder().addQueryParameter(parameter, value).build()
            try {
                publicClient.newCall(Request.Builder().url(url).get().build()).execute().use { response: Response ->
                    val body: ErrorBodyDto? = errorBody(response.body.string())
                    FieldAvailability.Outcome.from(response.code, body?.errorName, body?.message)
                }
            } catch (_: IOException) {
                FieldAvailability.Outcome.Undetermined
            }
        }

    /** `null` when the server could not be reached at all. */
    private suspend fun post(client: OkHttpClient, path: String, body: String?): Pair<Int, String>? =
        withContext(Dispatchers.IO) {
            val request: Request = Request.Builder()
                .url("$baseUrl$path")
                .post((body ?: "").toRequestBody(if (body != null) ApiService.JsonMediaType else null))
                .build()
            try {
                client.newCall(request).execute().use { response -> response.code to response.body.string() }
            } catch (_: IOException) {
                null
            }
        }

    private fun sessionCookies(): List<Cookie> = jar.all().filter { it.name in SESSION_COOKIE_NAMES }

    private fun isValid(cookies: List<Cookie>): Boolean = cookies.any { it.expiresAt > clock() }

    private fun hasValidSessionCookies(): Boolean = isValid(sessionCookies())

    private fun jarHoldsAUserSession(): Boolean {
        val cookies: List<Cookie> = sessionCookies()
        return isValid(cookies) && SessionCookie.namesAUser(cookies.map { it.value })
    }

    private fun adoptJarSession() {
        if (jarHoldsAUserSession()) runCatching { persistCookiesToVault() }
    }

    private fun persistCookiesToVault() {
        val cookies: List<Cookie> = sessionCookies()
        if (cookies.isEmpty()) throw AuthException(AuthFailure.NoSessionCookies)
        val stored: List<StoredCookie> = cookies.map {
            StoredCookie(it.name, it.value, it.domain, it.path, it.expiresAt, it.secure, it.httpOnly, it.hostOnly)
        }
        val data: ByteArray = json.encodeToString(ListSerializer(StoredCookie.serializer()), stored).encodeToByteArray()
        if (!vault.save(data)) throw AuthException(AuthFailure.Storage)
    }

    private fun persistedSessionCookies(): List<Cookie> {
        val data: ByteArray = vault.load() ?: return emptyList()
        val stored: List<StoredCookie> = try {
            json.decodeFromString(ListSerializer(StoredCookie.serializer()), data.decodeToString())
        } catch (_: IllegalArgumentException) {
            vault.delete()
            return emptyList()
        }
        // Filtered on the way out as well as in, so an entry written under a wider rule cannot widen it today.
        return stored.filter { it.name in SESSION_COOKIE_NAMES }.map { cookie ->
            Cookie.Builder()
                .name(cookie.name)
                .value(cookie.value)
                .path(cookie.path)
                .expiresAt(cookie.expiresAt)
                .apply {
                    if (cookie.hostOnly) hostOnlyDomain(cookie.domain) else domain(cookie.domain)
                    if (cookie.secure) secure()
                    if (cookie.httpOnly) httpOnly()
                }
                .build()
        }
    }

    private fun restoreCookiesFromVault() {
        persistedSessionCookies().forEach(jar::put)
    }

    private fun errorBody(text: String): ErrorBodyDto? = try {
        json.decodeFromString(ErrorBodyDto.serializer(), text)
    } catch (_: IllegalArgumentException) {
        null
    }

    companion object {
        const val LOGIN_PATH: String = "/auth/login"
        const val LOGOUT_PATH: String = "/auth/logout"
        const val SIGNUP_PATH: String = "/auth/signup"
        const val USERNAME_AVAILABILITY_PATH: String = "/auth/username-availability"
        const val EMAIL_AVAILABILITY_PATH: String = "/auth/email-availability"
        const val RESET_PASSWORD_PATH: String = "/auth/reset-password"
        val SESSION_COOKIE_NAMES: Set<String> = setOf("inventaire:session", "inventaire:session.sig")
    }
}
