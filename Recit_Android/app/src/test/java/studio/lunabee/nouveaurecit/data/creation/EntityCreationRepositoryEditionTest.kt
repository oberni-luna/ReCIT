package studio.lunabee.nouveaurecit.data.creation

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import java.io.File
import java.util.UUID

/**
 * `EntityCreationModelEditionTests`: changing an edition that exists, against a local server — every
 * request is redirected from inventaire.io to it. What is asserted is the order of the calls (the picture
 * before the claim that names it) and what a failure halfway leaves: what landed is not sent again.
 */
class EntityCreationRepositoryEditionTest {
    private lateinit var server: MockWebServer
    private lateinit var repository: EntityCreationRepository
    private lateinit var cover: File

    private val hash: String = "75407f010cff3581bd373cc8ada59ad9259bf17a"
    private val newHash: String = "0123456789abcdef0123456789abcdef01234567"
    private val original: EditionClaims = EditionClaims(
        uri = "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
        title = "Lucioles",
        coverHash = hash,
        isbn = "978-2-37049-300-2",
        workUris = listOf("inv:work"),
    )

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        repository = EntityCreationRepository(api = ApiService(client("session")), publicApi = ApiService(client("public")))
        cover = File.createTempFile("cover", ".jpg").apply { writeBytes(byteArrayOf(1, 2, 3)) }
    }

    @After
    fun tearDown() {
        server.close()
        cover.delete()
    }

    /** A client sent to the local server, which says in a header which of the two it is. */
    private fun client(name: String): OkHttpClient = OkHttpClient.Builder()
        .addInterceptor { chain ->
            val redirected = chain.request().url.newBuilder().scheme("http").host(server.hostName).port(server.port).build()
            chain.proceed(chain.request().newBuilder().url(redirected).header(CLIENT_HEADER, name).build())
        }
        .build()

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    private fun ok() = answer("""{"ok":true}""")

    private fun requests(): List<RecordedRequest> = List(server.requestCount) { server.takeRequest() }

    private fun body(request: RecordedRequest): String = request.body?.utf8().orEmpty()

    private fun update(request: RecordedRequest): EditionClaimUpdate =
        ApiService.DefaultJson.decodeFromString(EditionClaimUpdate.serializer(), body(request))

    private suspend fun failure(edit: EditionEdit): EditionSaveFailure =
        repository.saveEdition(edit) as? EditionSaveFailure ?: throw AssertionError("expected a failure")

    private suspend fun saved(edit: EditionEdit): EditionEdit =
        (repository.saveEdition(edit) as? EditionSaveResult.Saved ?: throw AssertionError("expected a success")).edit

    // Reading

    @Test
    fun theEditionIsReadCookielessUnderItsCanonicalUri() = runTest {
        answer(
            """{"entities":{"inv:69c1353d3d6a4fb21005c0d7367e1eb4":{"uri":"inv:69c1353d3d6a4fb21005c0d7367e1eb4",
              "claims":{"wdt:P1476":["Lucioles"],"invp:P2":["$hash"],"wdt:P212":["978-2-37049-300-2"],"wdt:P629":["inv:work"]}}},
              "redirects":{"isbn:9782370493002":"inv:69c1353d3d6a4fb21005c0d7367e1eb4"}}""",
        )

        assertEquals(original, repository.editableEdition("isbn:9782370493002"))

        val request: RecordedRequest = requests().single()
        assertEquals("public", request.headers[CLIENT_HEADER])
        assertEquals("/api/entities/by-uris", request.url.encodedPath)
        assertEquals("isbn:9782370493002", request.url.queryParameter("uris"))
        assertEquals("info|claims|labels", request.url.queryParameter("attributes"))
        assertTrue(request.url.queryParameter("relatives")!!.startsWith("wdt:P123|wdt:P195|wdt:P655"))
    }

    @Test
    fun anAnswerWithNoInvEditionIsAFailure() = runTest {
        answer("""{"entities":{"wd:Q1":{"uri":"wd:Q1"}}}""")
        try {
            repository.editableEdition("wd:Q1")
            fail("expected a failure")
        } catch (_: NetworkError.BadResponse) {
        }
    }

    @Test
    fun theEntitiesAnEditionNamesAreReadWithTheirLabelsLanguagesInASecondCall() = runTest {
        answer(
            """{"entities":{
              "inv:e":{"uri":"inv:e","type":"edition","claims":{"wdt:P1476":["Lucioles"],"wdt:P123":["inv:publisher"],
                "wdt:P195":["inv:collection"],"wdt:P407":["wd:Q150"],"wdt:P1104":[256]}},
              "inv:publisher":{"uri":"inv:publisher","type":"publisher","labels":{"fr":"Le Sous-Bois"}},
              "inv:collection":{"uri":"inv:collection","type":"collection","claims":{"wdt:P1476":["Nature writing"]}}},
              "redirects":{"isbn:9782370493002":"inv:e"}}""",
        )
        answer("""{"entities":{"wd:Q150":{"uri":"wd:Q150","labels":{"fr":"français"}}}}""")

        val claims: EditionClaims = repository.editableEdition("isbn:9782370493002")

        assertEquals("inv:e", claims.uri)
        assertEquals(listOf("Le Sous-Bois"), claims.properties.entities(EditionProperty.Publisher).map { it.label })
        // A collection has no label: its title names it.
        assertEquals(listOf("Nature writing"), claims.properties.entities(EditionProperty.Collection).map { it.label })
        assertEquals(listOf("français"), claims.properties.entities(EditionProperty.Language).map { it.label })
        assertEquals(ClaimLiteral.Integer(256), claims.properties.literal(EditionProperty.NumberOfPages))
        val second: RecordedRequest = requests()[1]
        assertEquals("wd:Q150", second.url.queryParameter("uris"))
        assertEquals("public", second.headers[CLIENT_HEADER])
    }

    @Test
    fun theWorkIsDescribedWithItsAuthorsByNameAndUri() = runTest {
        answer(
            """{"entities":{
              "inv:work":{"uri":"inv:work","labels":{"fr":"Penss et les plis du monde"},"claims":{"wdt:P50":["wd:Q3177937"]}},
              "wd:Q3177937":{"uri":"wd:Q3177937","labels":{"fr":"Jérémie Moreau"}}}}""",
        )

        val work: EditionWork = repository.describeEditionWorks(listOf("inv:work", "inv:gone")).single()

        assertEquals("Penss et les plis du monde", work.title)
        assertEquals("fr", work.titleLanguage)
        assertEquals(listOf("wd:Q3177937"), work.authors.map { it.uri })
        assertEquals(listOf("Jérémie Moreau"), work.authors.map { it.trimmedName })
        val request: RecordedRequest = requests().single()
        assertEquals("wdt:P50", request.url.queryParameter("relatives"))
        assertEquals("public", request.headers[CLIENT_HEADER])
    }

    // Saving

    @Test
    fun thePictureGoesUpFirstThenEachClaimTitleBeforeCover() = runTest {
        answer("""{"cover":"/img/entities/$newHash"}""")
        ok()
        ok()
        val edit: EditionEdit = EditionEdit(original).copy(title = "Lucioles II").withCover(cover.absolutePath)

        val saved: EditionEdit = saved(edit)

        val requests: List<RecordedRequest> = requests()
        assertEquals(
            listOf("/api/images/upload", "/api/entities/update-claim", "/api/entities/update-claim"),
            requests.map { it.url.encodedPath },
        )
        assertEquals(listOf("POST", "PUT", "PUT"), requests.map { it.method })
        assertTrue(requests.all { it.headers[CLIENT_HEADER] == "session" })
        assertEquals(
            listOf(
                EditionClaimUpdate.of(original.uri, EditableClaimProperty.Title, "Lucioles", "Lucioles II"),
                EditionClaimUpdate.of(original.uri, EditableClaimProperty.Cover, hash, newHash),
            ),
            requests.drop(1).map(::update),
        )
        assertTrue(!saved.hasChanges)
        assertEquals(newHash, saved.original.coverHash)
    }

    @Test
    fun anUploadThatAnswersNoHashFailsBeforeAnyClaimIsSent() = runTest {
        answer("""{"cover":"/img/entities/abc123"}""")
        val edit: EditionEdit = EditionEdit(original).withCover(cover.absolutePath)

        val failure: EditionSaveFailure = failure(edit)

        assertTrue(failure.underlying is NetworkError.BadResponse)
        assertEquals(1, server.requestCount)
    }

    @Test
    fun aFailureHalfwayKeepsWhatLandedAndTheRetrySendsOnlyTheRest() = runTest {
        answer("""{"cover":"/img/entities/$newHash"}""")
        ok()
        answer("", code = 500)
        val edit: EditionEdit = EditionEdit(original).copy(title = "Lucioles II").withCover(cover.absolutePath)

        val failure: EditionSaveFailure = failure(edit)

        val partial: EditionEdit = failure.edit
        assertEquals(CreateBookFailure.Network, failure.failure)
        assertEquals("Lucioles II", partial.original.title)
        assertEquals(newHash, partial.uploadedCoverHash)
        assertEquals(listOf(EditableClaimProperty.Cover.uri), partial.claimUpdates.map { it.property })

        ok()
        val saved: EditionEdit = saved(partial)

        val requests: List<RecordedRequest> = requests()
        // One upload in all: the retry hangs the picture already sent.
        assertEquals(1, requests.count { it.url.encodedPath == "/api/images/upload" })
        assertEquals(
            listOf(EditableClaimProperty.Title.uri, EditableClaimProperty.Cover.uri, EditableClaimProperty.Cover.uri),
            requests.filter { it.url.encodedPath == "/api/entities/update-claim" }.map { update(it).property },
        )
        assertTrue(!saved.hasChanges)
    }

    @Test
    fun aNewWorkGoesUpAfterItsNewAuthorThenTheEditionIsPointedAtIt() = runTest {
        answer("""{"entity":{"uri":"inv:author"}}""")
        answer("""{"entity":{"uri":"inv:new-work"}}""")
        ok()
        ok()
        val opened: EditionEdit = EditionEdit(original.copy(coverHash = null), listOf(EditionWork(uri = "inv:work", title = "Lucioles")))
        val started: EditionEdit = opened.detachWork(opened.works[0].id).startNewWork("Lucioles, l'œuvre")
        val edit: EditionEdit = started.updatingWork(started.works[0].id) { it.addAuthor(NewBookAuthor(name = "Lucie Durand")) }

        val saved: EditionEdit = saved(edit)

        val requests: List<RecordedRequest> = requests()
        assertEquals(
            listOf("/api/entities", "/api/entities", "/api/entities/update-claim", "/api/entities/update-claim"),
            requests.map { it.url.encodedPath },
        )
        assertEquals(listOf("POST", "POST", "PUT", "PUT"), requests.map { it.method })
        assertTrue(body(requests[0]).contains(""""labels":{"""))
        assertTrue(body(requests[0]).contains("Lucie Durand"))
        assertTrue(body(requests[0]).contains(""""claims":{"wdt:P31":["wd:Q5"]}"""))
        assertTrue(body(requests[1]).contains(""""claims":{"wdt:P31":["wd:Q47461344"],"wdt:P50":["inv:author"]}"""))
        // The old work is detached, then the new one claimed.
        assertEquals(EditionClaimUpdate.of(original.uri, EditableClaimProperty.Work, "inv:work", null), update(requests[2]))
        assertEquals(EditionClaimUpdate.of(original.uri, EditableClaimProperty.Work, null, "inv:new-work"), update(requests[3]))
        assertEquals(listOf("inv:new-work"), saved.original.workUris)
        assertTrue(!saved.hasChanges)
    }

    @Test
    fun aWorkThatFailsToBeCreatedLeavesItsAuthorCreatedAndTheRetryReusesThem() = runTest {
        answer("""{"entity":{"uri":"inv:author"}}""")
        answer("", code = 500)
        val started: EditionEdit = EditionEdit(original.copy(workUris = emptyList())).startNewWork("Lucioles")
        val id: UUID = started.works[0].id
        val edit: EditionEdit = started.updatingWork(id) { it.addAuthor(NewBookAuthor(name = "Lucie Durand")) }

        val partial: EditionEdit = failure(edit).edit

        assertEquals(listOf("inv:author"), partial.works[0].authors.map { it.uri })
        assertEquals(EditionEditStep.CreateWork(id, "Lucioles", partial.labelLanguage, listOf("inv:author")), partial.nextStep)
    }

    @Test
    fun aWorkRenamedIsSentAsALabelAfterTheClaims() = runTest {
        ok()
        ok()
        val opened: EditionEdit = EditionEdit(
            original,
            listOf(EditionWork("inv:work", "Lucioles", listOf(NewBookAuthor(name = "Lucie Durand", uri = "inv:lucie")), titleLanguage = "fr")),
        )
        val edit: EditionEdit = opened.updatingWork(opened.works[0].id) { it.copy(title = "Lucioles, quinze fictions").removeAuthors(setOf(0)) }

        val saved: EditionEdit = saved(edit)

        val requests: List<RecordedRequest> = requests()
        assertEquals(listOf("/api/entities/update-claim", "/api/entities/update-label"), requests.map { it.url.encodedPath })
        assertEquals(EditionClaimUpdate.of("inv:work", EditableClaimProperty.Author, "inv:lucie", null), update(requests[0]))
        assertEquals(
            EntityLabelUpdate(uri = "inv:work", lang = "fr", value = "Lucioles, quinze fictions"),
            ApiService.DefaultJson.decodeFromString(EntityLabelUpdate.serializer(), body(requests[1])),
        )
        assertTrue(!saved.hasChanges)
    }

    @Test
    fun aNewPublisherIsCreatedThenACollectionUnderItThenTheClaimsACountAsANumber() = runTest {
        answer("""{"entity":{"uri":"inv:publisher"}}""")
        answer("""{"entity":{"uri":"inv:collection"}}""")
        ok()
        ok()
        ok()
        val opened: EditionEdit = EditionEdit(EditionClaims(uri = original.uri, title = "Lucioles", workUris = listOf("inv:work"), labelLanguage = "fr"))
        val edit: EditionEdit = opened.copy(
            properties = opened.properties
                .add(EditionEntityValue(label = "Nature writing"), EditionProperty.Collection)
                .add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher)
                .setLiteral(ClaimLiteral.Integer(256), EditionProperty.NumberOfPages),
        )
        assertTrue(edit.isSaveable)

        val saved: EditionEdit = saved(edit)

        val requests: List<RecordedRequest> = requests()
        assertEquals(
            listOf("/api/entities", "/api/entities", "/api/entities/update-claim", "/api/entities/update-claim", "/api/entities/update-claim"),
            requests.map { it.url.encodedPath },
        )
        assertEquals("""{"labels":{"fr":"Le Sous-Bois"},"claims":{"wdt:P31":["wd:Q2085381"]}}""", body(requests[0]))
        assertEquals(
            """{"labels":{},"claims":{"wdt:P31":["wd:Q20655472"],"wdt:P1476":["Nature writing"],"wdt:P123":["inv:publisher"]}}""",
            body(requests[1]),
        )
        assertEquals(
            listOf(ClaimLiteral.Text("inv:publisher"), ClaimLiteral.Text("inv:collection"), ClaimLiteral.Integer(256)),
            requests.drop(2).map { update(it).newValue },
        )
        assertTrue(body(requests[4]).contains(""""new-value":256"""))
        assertTrue(!saved.hasChanges)
    }

    private companion object {
        const val CLIENT_HEADER: String = "X-Test-Client"
    }
}
