package studio.lunabee.nouveaurecit.data.creation

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError

/**
 * `EntityCreationModelTests`: the calls that publish a book, against a local server. Every request is
 * redirected from inventaire.io to it, so nothing here touches the network.
 */
class EntityCreationRepositoryTest {
    private lateinit var server: MockWebServer
    private lateinit var repository: EntityCreationRepository
    private val draft: NewBookDraft = NewBookDraft(isbn = "9782070360024", title = "La Main gauche de la nuit", authorName = "Ursula K. Le Guin")

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
        repository = EntityCreationRepository(api = ApiService(client), publicApi = ApiService(client))
    }

    @After
    fun tearDown() {
        server.close()
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    @Test
    fun theCanonicalUriOfTheEditionIsAnswered() = runTest {
        answer("""{"entries":[{"edition":{"uri":"inv:2078ee8e","created":true},"works":[{"uri":"inv:w","created":true}]}]}""")
        assertEquals("inv:2078ee8e", repository.createEdition(draft))
        val request: RecordedRequest = server.takeRequest()
        assertEquals("/api/entities/resolve", request.url.encodedPath)
        assertTrue(request.body!!.utf8().contains("\"create\":true"))
    }

    @Test
    fun anEditionResolvedRatherThanCreatedIsAcceptedAsItIs() = runTest {
        answer("""{"entries":[{"edition":{"uri":"inv:existing","resolved":true}}]}""")
        assertEquals("inv:existing", repository.createEdition(draft))
    }

    @Test
    fun anAnswerWithoutAnEditionUriFailsInsteadOfGuessing() = runTest {
        answer("""{"entries":[{"edition":{"resolved":false}}]}""")
        try {
            repository.createEdition(draft)
            fail("expected a failure")
        } catch (_: NetworkError.BadResponse) {
        }
    }

    @Test
    fun aRefusalReachesTheCallerAsItsStatus() = runTest {
        answer("""{"status_verbose":"invalid isbn"}""", code = 400)
        try {
            repository.createEdition(draft)
            fail("expected a failure")
        } catch (error: NetworkError.BadStatus) {
            assertEquals(CreateBookFailure.Refused, CreateBookFailure.from(error))
        }
    }

    @Test
    fun theDryRunAnswersOnlyAWorkTheServerRecognised() = runTest {
        answer("""{"entries":[{"edition":{},"works":[{"uri":"wd:Q1210925","resolved":true}]}]}""")
        assertEquals("wd:Q1210925", repository.recogniseWork(draft))
        assertTrue(server.takeRequest().body!!.utf8().contains("\"create\":false"))

        answer("""{"entries":[{"edition":{},"works":[{"resolved":false}]}]}""")
        assertNull(repository.recogniseWork(draft))

        answer("", code = 500)
        assertNull(repository.recogniseWork(draft))
    }

    @Test
    fun theLanguageComesFromTheIsbnGroupOrNotAtAll() = runTest {
        answer("""{"groupLang":"fr","groupLangUri":"wd:Q150","isValid":true}""")
        assertEquals(EditionLanguage(uri = "wd:Q150", code = "fr"), repository.editionLanguage("978-2-07-036002-4"))
        assertEquals("isbn=9782070360024", server.takeRequest().url.encodedQuery)

        answer("""{"isValid":true}""")
        assertNull(repository.editionLanguage("9790000000001"))

        answer("", code = 400)
        assertNull(repository.editionLanguage("123"))
    }

    @Test
    fun theCoverUrlComesBackUnderTheFieldNameAndAFailedUploadCostsNothing() = runTest {
        answer("""{"cover":"/img/entities/9f1b"}""")
        assertEquals("/img/entities/9f1b", repository.uploadCover(byteArrayOf(1, 2, 3)))
        val request: RecordedRequest = server.takeRequest()
        assertEquals("/api/images/upload", request.url.encodedPath)
        assertEquals("container=entities", request.url.encodedQuery)
        assertTrue(request.headers["Content-Type"]!!.startsWith("multipart/form-data"))
        assertTrue(request.body!!.utf8().contains("name=\"cover\"; filename=\"cover.jpg\""))

        answer("", code = 500)
        assertNull(repository.uploadCover(byteArrayOf(1)))
    }
}
