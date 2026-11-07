package studio.lunabee.exlibris.backend.entities

import io.ktor.client.request.get
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.measureTimedValue

class RelayFailureRoutesTest {
    @Test
    fun `inventaire stopped answers 502 in the error shape, at once`() {
        val stopped: InventaireStub = InventaireStub().also { it.close() }
        relayTest(stopped) {
            val (response: HttpResponse, elapsed: Duration) =
                measureTimedValue { client.get("/api/entities/by-uris?uris=wd:Q8337") }

            assertBadGateway(response)
            assertTrue(elapsed < 2.seconds, "$elapsed")
        }
    }

    @Test
    fun `inventaire silent past 10 seconds answers 502 in the error shape`() =
        InventaireStub().use { stub ->
            stub.answer = { StubAnswer.json("{}").let { StubAnswer(it.status, it.body, it.headers, SILENCE_MILLIS) } }
            relayTest(stub) {
                val (response: HttpResponse, elapsed: Duration) =
                    measureTimedValue { client.get("/api/data/isbn?isbn=9782070368228") }

                assertBadGateway(response)
                assertTrue(elapsed < 11.seconds, "$elapsed")
            }
        }

    private suspend fun assertBadGateway(response: HttpResponse) {
        assertEquals(HttpStatusCode.BadGateway, response.status)
        val body: JsonObject = Json.parseToJsonElement(response.bodyAsText()).jsonObject
        assertEquals("502", body.getValue("status").jsonPrimitive.content)
        assertEquals("bad gateway", body.getValue("status_verbose").jsonPrimitive.content)
        assertNull(response.headers["Set-Cookie"])
    }

    private companion object {
        const val SILENCE_MILLIS: Long = 15_000
    }
}
