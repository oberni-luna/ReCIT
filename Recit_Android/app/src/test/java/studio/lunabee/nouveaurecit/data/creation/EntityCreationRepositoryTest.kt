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
    private val draft: NewBookDraft = NewBookDraft(
        isbn = "9782070360024",
        title = "La Main gauche de la nuit",
        authors = listOf(NewBookAuthor(name = "Ursula K. Le Guin")),
    )

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
    fun theCoverUrlComesBackUnderTheFieldNameAbsoluteAndAFailedUploadCostsNothing() = runTest {
        answer("""{"cover":"/img/entities/9f1b"}""")
        // Absolute: `resolve` refuses an edition seed whose image is not a url it can fetch.
        assertEquals("https://inventaire.io/img/entities/9f1b", repository.uploadCover(byteArrayOf(1, 2, 3)))
        val request: RecordedRequest = server.takeRequest()
        assertEquals("/api/images/upload", request.url.encodedPath)
        assertEquals("container=entities", request.url.encodedQuery)
        assertTrue(request.headers["Content-Type"]!!.startsWith("multipart/form-data"))
        assertTrue(request.body!!.utf8().contains("name=\"cover\"; filename=\"cover.jpg\""))

        answer("", code = 500)
        assertNull(repository.uploadCover(byteArrayOf(1)))
    }

    @Test
    fun publishersAreCreatedBeforeCollectionsEachHandedBackAsItLands() = runTest {
        answer("""{"entity":{"uri":"inv:publisher"}}""")
        answer("""{"entity":{"uri":"inv:collection"}}""")
        var properties: EditionProperties = EditionProperties()
            .add(EditionEntityValue(label = "Nature writing"), EditionProperty.Collection)
            .add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher)

        val created: MutableList<String> = mutableListOf()
        repository.createPendingEntities(properties, "fr") { id, uri ->
            properties = properties.entityCreated(id, uri)
            created += uri
        }

        assertEquals(listOf("inv:publisher", "inv:collection"), created)
        assertTrue(properties.pendingEntities.isEmpty())
        val publisher: String = server.takeRequest().body!!.utf8()
        assertTrue(publisher, publisher.contains(""""labels":{"fr":"Le Sous-Bois"}"""))
        val collection: RecordedRequest = server.takeRequest()
        assertEquals("/api/entities", collection.url.encodedPath)
        assertTrue(collection.body!!.utf8().contains(""""wdt:P123":["inv:publisher"]"""))
    }

    @Test
    fun aCreationFailingHalfwayKeepsWhatExistsAndTheRetryCreatesOnlyTheRest() = runTest {
        answer("""{"entity":{"uri":"inv:publisher"}}""")
        answer("", code = 500)
        var draft: NewBookDraft = draft.copy(
            workUri = "wd:Q1",
            properties = EditionProperties()
                .add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher)
                .add(EditionEntityValue(label = "Irina Petrova"), EditionProperty.contributors[0]),
        )
        try {
            repository.createPendingEntities(draft.properties, draft.labelLanguage) { id, uri -> draft = draft.entityCreated(id, uri) }
            fail("expected a failure")
        } catch (_: NetworkError.BadStatus) {
        }
        assertEquals(listOf("Irina Petrova"), draft.properties.pendingEntities.map { it.entity.label })

        answer("""{"entity":{"uri":"inv:irina"}}""")
        repository.createPendingEntities(draft.properties, draft.labelLanguage) { id, uri -> draft = draft.entityCreated(id, uri) }
        assertEquals(3, server.requestCount)
        assertTrue(draft.properties.pendingEntities.isEmpty())
        assertEquals(
            listOf(ClaimLiteral.Text("inv:publisher")),
            ResolveRequestBuilder.request(draft, create = true, language = "fr").entries.single().edition.claims?.get("wdt:P123"),
        )
    }

    @Test
    fun aSearchIsRestrictedToOneTypeBestMatchFirst() = runTest {
        answer(
            """{"results":[
              {"id":"a","type":"publishers","uri":"wd:Q1","label":"Folio","_score":1.0},
              {"id":"b","type":"publishers","uri":"wd:Q336718","label":"Gallimard","description":"maison","image":"/img/x","_score":9.0}
            ]}""",
        )
        val hits: List<EntitySearchHit> = repository.searchEntities(" Gallimard ", EntitySearchType.Publishers)
        assertEquals(listOf("wd:Q336718", "wd:Q1"), hits.map { it.uri })
        assertEquals("https://inventaire.io/img/x", hits[0].image)
        val request: RecordedRequest = server.takeRequest()
        assertEquals("publishers", request.url.queryParameter("types"))
        assertEquals("Gallimard", request.url.queryParameter("search"))
    }

    @Test
    fun foundWorksAreCompletedWithTheirAuthorsAndYearOrKeepTheirDescription() = runTest {
        answer("""{"results":[{"id":"w","type":"works","uri":"wd:Q102036201","label":"Le Ministère du futur","description":"roman"}]}""")
        answer(
            """{"entities":{
              "wd:Q102036201":{"uri":"wd:Q102036201","labels":{"fr":"Le Ministère du futur"},
                "claims":{"wdt:P50":["wd:Q130779"],"wdt:P577":["2020-10-06"]}},
              "wd:Q130779":{"uri":"wd:Q130779","labels":{"fr":"Kim Stanley Robinson"}}}}""",
        )
        val candidate: WorkCandidate = repository.searchWorks("ministère du futur").single()
        assertEquals("Kim Stanley Robinson · 2020", candidate.detail)
        server.takeRequest()
        assertEquals("wdt:P50", server.takeRequest().url.queryParameter("relatives"))

        answer("", code = 500)
        val fallback: List<WorkCandidate> =
            repository.describeCandidates(listOf(EntitySearchHit(uri = "inv:abc", label = "Ratna krila", description = "roman (2011)")))
        assertEquals("roman (2011)", fallback.single().detail)
        assertTrue(repository.describeCandidates(emptyList()).isEmpty())
    }
}
