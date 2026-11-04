package studio.lunabee.nouveaurecit.data.transactions

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.data.TransactionRepository
import studio.lunabee.nouveaurecit.network.ApiService

/**
 * The request against a local server: every call is redirected from inventaire.io to it, so nothing
 * here touches the network, and nothing is ever asked of a real account.
 */
class TransactionRequestRepositoryTest {
    private lateinit var server: MockWebServer
    private lateinit var repository: TransactionRepository

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        val client: OkHttpClient = OkHttpClient.Builder()
            .addInterceptor { chain ->
                val redirected = chain.request().url.newBuilder().scheme("http").host(server.hostName).port(server.port).build()
                chain.proceed(chain.request().newBuilder().url(redirected).build())
            }
            .build()
        repository = TransactionRepository(ApiService(client))
    }

    @After
    fun tearDown() {
        server.close()
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    @Test
    fun theRequestSendsTheItemAndTheMessageOnly() = runTest {
        answer("""{"transaction":{"_id":"t1","_rev":"1-a","item":"i1","transaction":"lending","state":"requested"},"warnings":[]}""")

        val id: String = repository.request(itemId = "i1", message = "  Je te le rends dans un mois.\n")

        assertEquals("t1", id)
        val recorded: RecordedRequest = server.takeRequest()
        assertEquals("POST", recorded.method)
        assertEquals("/api/transactions/request", recorded.url.encodedPath)
        assertEquals(null, recorded.url.query)
        val body: JsonObject = Json.parseToJsonElement(recorded.body!!.utf8()).jsonObject
        assertEquals(
            JsonObject(mapOf("item" to JsonPrimitive("i1"), "message" to JsonPrimitive("Je te le rends dans un mois."))),
            body,
        )
    }

    @Test
    fun aSecondRequestForTheSameCopyIsSaidAsSuch() = runTest {
        answer("""{"status":403,"status_verbose":"user already made a request on this item"}""", code = 403)
        try {
            repository.request(itemId = "i1", message = "Encore moi")
            fail("The server refused")
        } catch (error: Exception) {
            assertEquals(TransactionRequestFailure.AlreadyRequested, TransactionRequestFailure.from(error))
        }
    }
}
