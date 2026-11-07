package studio.lunabee.exlibris.backend.entities

import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.spi.ILoggingEvent
import ch.qos.logback.core.read.ListAppender
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsBytes
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.FixtureAssertions
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RelayAnswerRoutesTest {
    @Test
    fun `inventaire's JSON comes back byte for byte, without its session or anyone's`() =
        InventaireStub().use { stub ->
            val captured: String = FixtureAssertions.read("entities/by-uris.wd-Q8337.fr.json")
            stub.answer = {
                StubAnswer.json(
                    captured,
                    headers = mapOf(HttpHeaders.SetCookie to "inventaire:session=eyJ0aW1lc3RhbXAiOjF9; path=/"),
                )
            }
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val anonymous: HttpResponse = client.get("/api/entities/by-uris?uris=wd:Q8337&lang=fr")
                val signedIn: HttpResponse =
                    client.get("/api/entities/by-uris?uris=wd:Q8337&lang=fr") { sendCookies(reader.cookies) }

                listOf(anonymous, signedIn).forEach { response ->
                    assertEquals(HttpStatusCode.OK, response.status)
                    assertEquals("application/json; charset=utf-8", response.headers[HttpHeaders.ContentType])
                    assertEquals(captured, response.bodyAsText())
                    assertNull(response.headers[HttpHeaders.SetCookie])
                }
            }
        }

    @Test
    fun `an image keeps its caching headers, and its ETag answers 304`() =
        InventaireStub().use { stub ->
            val bytes: ByteArray = ByteArray(IMAGE_BYTES) { it.toByte() }
            val etag = "\"5f1-18c4\""
            val cache: Map<String, String> =
                mapOf(
                    HttpHeaders.CacheControl to "public, max-age=31536000, immutable",
                    HttpHeaders.ETag to etag,
                    HttpHeaders.LastModified to "Tue, 04 Jun 2024 09:12:44 GMT",
                )
            stub.answer = { request ->
                if (request.header(HttpHeaders.IfNoneMatch) == etag) {
                    StubAnswer(status = 304, headers = cache)
                } else {
                    StubAnswer(status = 200, body = bytes, headers = cache + (HttpHeaders.ContentType to "image/jpeg"))
                }
            }
            relayTest(stub) {
                val path = "/img/entities/3af17a8d008b00047d93b00b3f77fbe00df75877"

                val image: HttpResponse = client.get(path)
                val revalidated: HttpResponse = client.get(path) { header(HttpHeaders.IfNoneMatch, etag) }

                assertEquals(HttpStatusCode.OK, image.status)
                assertEquals("image/jpeg", image.headers[HttpHeaders.ContentType])
                assertContentEquals(bytes, image.bodyAsBytes())
                assertEquals(HttpStatusCode.NotModified, revalidated.status)
                assertTrue(revalidated.bodyAsBytes().isEmpty())
                listOf(image, revalidated).forEach { response ->
                    cache.forEach { (name, value) -> assertEquals(value, response.headers[name], name) }
                    assertNull(response.headers[HttpHeaders.SetCookie])
                }
            }
        }

    @Test
    fun `an error inventaire writes comes back as inventaire wrote it`() =
        InventaireStub().use { stub ->
            val notFound = """{"status":400,"message":"invalid uri: foo","error_type":"invalid_parameter"}"""
            stub.answer = { StubAnswer.json(notFound, status = 400) }
            relayTest(stub) {
                val response: HttpResponse = client.get("/api/entities/by-uris?uris=foo")

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertEquals(notFound, response.bodyAsText())
            }
        }

    @Test
    fun `a 429 from inventaire reaches the app as is, and is logged with its path`() =
        InventaireStub().use { stub ->
            val limited = """{"status":429,"message":"Too little time between requests"}"""
            stub.answer = { StubAnswer.json(limited, status = 429) }
            val logs: ListAppender<ILoggingEvent> = ListAppender<ILoggingEvent>().apply { start() }
            val logger: Logger = LoggerFactory.getLogger(InventaireClient::class.java) as Logger
            logger.addAppender(logs)
            try {
                relayTest(stub) {
                    val response: HttpResponse = client.get("/api/search?types=works&search=dune&lang=fr")

                    assertEquals(HttpStatusCode.TooManyRequests, response.status)
                    assertEquals(limited, response.bodyAsText())
                }
            } finally {
                logger.detachAppender(logs)
            }

            val lines: List<String> = logs.list.map { it.formattedMessage }
            assertEquals(listOf("inventaire.io answered 429 to /api/search"), lines)
        }

    private companion object {
        const val IMAGE_BYTES: Int = 70_000
    }
}
