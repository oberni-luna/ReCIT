package studio.lunabee.exlibris.backend

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.testcontainers.containers.GenericContainer
import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

/** The Mailpit Compose runs, read through its HTTP API: the e-mails the backend really sent. */
class TestMailpit : AutoCloseable {
    private val container: GenericContainer<*> =
        GenericContainer("axllent/mailpit")
            .withExposedPorts(SMTP_PORT, API_PORT)
            .withEnv("MP_SMTP_DISABLE_RDNS", "true")
    private val http: HttpClient = HttpClient.newHttpClient()

    val host: String get() = container.host
    val smtpPort: Int get() = container.getMappedPort(SMTP_PORT)

    fun start() {
        container.start()
    }

    /** The plain-text bodies of the e-mails sent to [address], newest first. */
    fun textsTo(address: String): List<String> {
        val query: String = URLEncoder.encode("to:\"$address\"", Charsets.UTF_8)
        val messages = get("/api/v1/search?query=$query")["messages"]?.jsonArray.orEmpty()
        return messages.map { message ->
            val id: String =
                message.jsonObject
                    .getValue("ID")
                    .jsonPrimitive.content
            get("/api/v1/message/$id").getValue("Text").jsonPrimitive.content
        }
    }

    /** The subject of the newest e-mail sent to [address]. */
    fun latestSubjectTo(address: String): String? {
        val query: String = URLEncoder.encode("to:\"$address\"", Charsets.UTF_8)
        return get("/api/v1/search?query=$query")["messages"]
            ?.jsonArray
            ?.firstOrNull()
            ?.jsonObject
            ?.get("Subject")
            ?.jsonPrimitive
            ?.content
    }

    override fun close() {
        container.stop()
    }

    private fun get(path: String): JsonObject {
        val uri = URI("http://${container.host}:${container.getMappedPort(API_PORT)}$path")
        val response: HttpResponse<String> =
            http.send(
                HttpRequest.newBuilder(uri).build(),
                HttpResponse.BodyHandlers.ofString(),
            )
        return Json.parseToJsonElement(response.body()).jsonObject
    }

    private companion object {
        const val SMTP_PORT: Int = 1025
        const val API_PORT: Int = 8025
    }
}
