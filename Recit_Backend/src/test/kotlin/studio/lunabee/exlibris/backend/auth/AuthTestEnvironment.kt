package studio.lunabee.exlibris.backend.auth

import io.ktor.client.HttpClient
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.server.config.ApplicationConfig
import io.ktor.server.testing.ApplicationTestBuilder
import io.ktor.server.testing.testApplication
import org.testcontainers.postgresql.PostgreSQLContainer
import studio.lunabee.exlibris.backend.TestMailpit
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.module
import java.sql.DriverManager
import java.util.UUID

/**
 * One Postgres and one Mailpit for every auth test, started on first use and stopped with the JVM. Tests share
 * them, so each one signs up accounts of its own ([newAccount]). Each `testApplication` is a fresh `module()`:
 * the in-memory rate limits start from zero.
 */
object AuthTestEnvironment {
    const val PASSWORD: String = "correct horse battery"

    val postgres: PostgreSQLContainer by lazy { TestPostgres.container().also { it.start() } }
    val mailpit: TestMailpit by lazy { TestMailpit().also { it.start() } }
    val config: ApplicationConfig by lazy { TestPostgres.config(postgres, mailpit) }

    /** The e-mails' plain-text bodies to [address], waiting a little for Mailpit to file them. */
    fun mailsTo(
        address: String,
        count: Int = 1,
    ): List<String> {
        repeat(MAIL_POLLS) {
            val texts: List<String> = mailpit.textsTo(address)
            if (texts.size >= count) return texts
            Thread.sleep(MAIL_POLL_MILLIS)
        }
        return mailpit.textsTo(address)
    }

    /** The path and query of the newest link to [path] mailed to [address]. */
    fun mailedLink(
        address: String,
        path: String,
        count: Int = 1,
    ): String {
        val link = Regex("""http://localhost:8080($path\?token=[A-Za-z0-9_-]+)""")
        return requireNotNull(mailsTo(address, count).firstNotNullOfOrNull { link.find(it)?.groupValues?.get(1) }) {
            "no $path link mailed to $address"
        }
    }

    /** Runs [statement] on the test database, behind the backend's back: to age a link, for instance. */
    fun execute(statement: String) {
        DriverManager.getConnection(postgres.jdbcUrl, postgres.username, postgres.password).use { connection ->
            connection.createStatement().use { it.execute(statement) }
        }
    }

    fun queryLong(query: String): Long =
        DriverManager.getConnection(postgres.jdbcUrl, postgres.username, postgres.password).use { connection ->
            connection.createStatement().use { statement ->
                statement.executeQuery(query).use { result ->
                    result.next()
                    result.getLong(1)
                }
            }
        }

    fun newAccount(): TestAccount {
        val suffix: String =
            UUID
                .randomUUID()
                .toString()
                .replace("-", "")
                .take(SUFFIX_LENGTH)
        return TestAccount(username = "reader_$suffix", email = "reader-$suffix@example.org")
    }

    private const val SUFFIX_LENGTH: Int = 12
    private const val MAIL_POLLS: Int = 50
    private const val MAIL_POLL_MILLIS: Long = 100
}

data class TestAccount(
    val username: String,
    val email: String,
)

fun authTest(block: suspend ApplicationTestBuilder.() -> Unit) =
    testApplication {
        environment { config = AuthTestEnvironment.config }
        application { module() }
        block()
    }

suspend fun HttpClient.postJson(
    path: String,
    json: String,
    cookies: Map<String, String> = emptyMap(),
): HttpResponse =
    post(path) {
        contentType(ContentType.Application.Json)
        setBody(json)
        sendCookies(cookies)
    }

suspend fun HttpClient.signup(
    account: TestAccount,
    password: String = AuthTestEnvironment.PASSWORD,
    language: String? = null,
): HttpResponse =
    post("/api/auth/signup") {
        contentType(ContentType.Application.Json)
        language?.let { header(HttpHeaders.AcceptLanguage, it) }
        setBody("""{"username":"${account.username}","email":"${account.email}","password":"$password"}""")
    }

suspend fun HttpClient.login(
    identifier: String,
    password: String = AuthTestEnvironment.PASSWORD,
): HttpResponse = postJson("/api/auth/login", """{"username":"$identifier","password":"$password"}""")

/** The cookies a response sets, by name, as a client would keep them: an expired one is dropped. */
fun HttpResponse.setCookies(): Map<String, String> =
    headers
        .getAll(HttpHeaders.SetCookie)
        .orEmpty()
        .filterNot { it.contains("expires=Thu, 01 Jan 1970") }
        .associate { header -> header.substringBefore(';').let { it.substringBefore('=') to it.substringAfter('=') } }

fun HttpRequestBuilder.sendCookies(cookies: Map<String, String>) {
    if (cookies.isNotEmpty()) {
        header(HttpHeaders.Cookie, cookies.entries.joinToString("; ") { "${it.key}=${it.value}" })
    }
}

/** Who a `Set-Cookie: inventaire:session=…` names, decoded as Android's `SessionCookie` does: base64url only. */
fun sessionUser(cookies: Map<String, String>): String? {
    val value: String = cookies[SessionCodec.COOKIE_NAME] ?: return null
    val json: String =
        java.util.Base64
            .getUrlDecoder()
            .decode(value)
            .decodeToString()
    return Regex(""""user":"([0-9a-f]{32})"""").find(json)?.groupValues?.get(1)
}
