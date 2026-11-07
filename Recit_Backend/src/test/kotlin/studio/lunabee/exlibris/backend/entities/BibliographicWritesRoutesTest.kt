package studio.lunabee.exlibris.backend.entities

import io.ktor.client.request.forms.formData
import io.ktor.client.request.forms.submitFormWithBinaryData
import io.ktor.client.request.request
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class BibliographicWritesRoutesTest {
    @Test
    fun `bibliographic writes answer 501 and never reach inventaire`() =
        InventaireStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val writes: List<Pair<HttpMethod, String>> =
                    listOf(
                        HttpMethod.Post to "/api/entities",
                        HttpMethod.Post to "/api/entities/resolve",
                        HttpMethod.Put to "/api/entities/update-claim",
                        HttpMethod.Put to "/api/entities/update-label",
                        HttpMethod.Put to "/api/entities/merge",
                        HttpMethod.Delete to "/api/tasks/by-uris",
                        HttpMethod.Post to "/img/entities/3af17a8d008b00047d93b00b3f77fbe00df75877",
                    )

                writes.forEach { (method, path) ->
                    val response: HttpResponse =
                        client.request(path) {
                            this.method = method
                            sendCookies(reader.cookies)
                            contentType(ContentType.Application.Json)
                            setBody("""{"entries":[]}""")
                        }

                    assertEquals(HttpStatusCode.NotImplemented, response.status, "$method $path")
                    assertEquals(NOT_IMPLEMENTED, response.bodyAsText())
                }
                assertTrue(stub.requests.isEmpty())
            }
        }

    @Test
    fun `a cover uploaded into entities answers 501`() =
        InventaireStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse =
                    client.submitFormWithBinaryData(
                        url = "/api/images/upload?container=entities",
                        formData =
                            formData {
                                append(
                                    "somefile",
                                    byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte()),
                                    Headers.build {
                                        append(HttpHeaders.ContentType, "image/jpeg")
                                        append(HttpHeaders.ContentDisposition, "filename=\"cover.jpg\"")
                                    },
                                )
                            },
                    ) { sendCookies(reader.cookies) }

                assertEquals(HttpStatusCode.NotImplemented, response.status)
                assertEquals(NOT_IMPLEMENTED, response.bodyAsText())
                assertTrue(stub.requests.isEmpty())
            }
        }

    private companion object {
        /** Decision 6's body, in #69's error shape. */
        const val NOT_IMPLEMENTED: String =
            """{"status":501,"status_verbose":"not implemented","message":"not implemented"}"""
    }
}
