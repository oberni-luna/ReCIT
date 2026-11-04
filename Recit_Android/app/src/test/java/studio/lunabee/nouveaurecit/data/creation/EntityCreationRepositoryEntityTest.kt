package studio.lunabee.nouveaurecit.data.creation

import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError

/**
 * `EntityCreationModelEntityTests` (iOS feature 0057): reading and saving a work or a person on its own,
 * against a local server — every request is redirected from inventaire.io to it. What is asserted is
 * what the form opens on, the order of the calls (the person created before the claim that names them,
 * the claims before the labels) and what a failure halfway leaves: what landed is not sent again.
 */
class EntityCreationRepositoryEntityTest {
    private lateinit var server: MockWebServer
    private lateinit var repository: EntityCreationRepository

    private val workUri: String = "inv:work"

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        repository = EntityCreationRepository(api = ApiService(client("session")), publicApi = ApiService(client("public")))
    }

    @After
    fun tearDown() {
        server.close()
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

    private fun claim(request: RecordedRequest): EditionClaimUpdate =
        ApiService.DefaultJson.decodeFromString(EditionClaimUpdate.serializer(), body(request))

    private fun label(request: RecordedRequest): EntityLabelUpdate =
        ApiService.DefaultJson.decodeFromString(EntityLabelUpdate.serializer(), body(request))

    /** A work as it opens: titled in French, one author, a type. */
    private fun opened(): EntityEdit = EntityEdit.open(
        uri = workUri,
        labels = mapOf("fr" to "Lucioles"),
        properties = EditionProperties(catalogue = EditionPropertyCatalogue.Work)
            .add(EditionEntityValue(uri = "inv:lucie", label = "Lucie Durand"), WorkProperties.Author)
            .setLiteral(ClaimLiteral.Text("wd:Q7725634"), WorkProperties.Type),
    )

    // Reading

    @Test
    fun aWorkIsReadCookielessInItsCatalogueItsEntitiesNamedByASecondCall() = runTest {
        answer(
            """{"entities":{"inv:work":{"uri":"inv:work","type":"work","originalLang":"fr",
              "labels":{"en":"Fireflies","fr":"Lucioles"},
              "claims":{"wdt:P31":["wd:Q7725634"],"wdt:P50":["inv:lucie"],"wdt:P407":["wd:Q150"],"wdt:P1545":["2"],
                "wdt:P648":["OL36858W"]}}}}""",
        )
        answer(
            """{"entities":{"inv:lucie":{"uri":"inv:lucie","labels":{"fr":"Lucie Durand"}},
              "wd:Q150":{"uri":"wd:Q150","labels":{"fr":"français"}}}}""",
        )

        val edit: EntityEdit = repository.editableEntity(workUri)

        assertEquals(EditionPropertyCatalogue.Work, edit.catalogue)
        assertEquals(listOf("fr", "en"), edit.labels.map { it.language })
        assertEquals("Lucioles", edit.displayName)
        assertEquals(listOf("Lucie Durand"), edit.properties.entities(WorkProperties.Author).map { it.label })
        // A work's `wdt:P407` is its original language, an entity.
        assertEquals(listOf("français"), edit.properties.entities(WorkProperties.OriginalLanguage).map { it.label })
        assertEquals(ClaimLiteral.Text("2"), edit.properties.literal(WorkProperties.SeriesOrdinal))
        assertEquals(ClaimLiteral.Text("wd:Q7725634"), edit.properties.literal(WorkProperties.Type))
        assertFalse(edit.hasChanges)

        val requests: List<RecordedRequest> = requests()
        assertEquals(listOf("public", "public"), requests.map { it.headers[CLIENT_HEADER] })
        assertEquals("info|claims|labels", requests[0].url.queryParameter("attributes"))
        assertEquals("inv:lucie|wd:Q150", requests[1].url.queryParameter("uris"))
    }

    @Test
    fun aPersonIsReadInTheirCatalogue() = runTest {
        answer(
            """{"entities":{"inv:lucie":{"uri":"inv:lucie","type":"human","labels":{"fr":"Lucie Durand"},
              "claims":{"wdt:P742":["L. D."],"wdt:P569":["1971-06"]}}}}""",
        )

        val edit: EntityEdit = repository.editableEntity("inv:lucie")

        assertEquals(EditionPropertyCatalogue.Human, edit.catalogue)
        assertEquals(listOf(ClaimLiteral.Text("L. D.")), edit.properties.values(HumanProperties.Pseudonym).mapNotNull { it.claim })
        assertEquals(ClaimLiteral.Text("1971-06"), edit.properties.literal(HumanProperties.BirthDate))
        // Nothing named: no second call.
        assertEquals(1, server.requestCount)
    }

    @Test
    fun aWikidataWorkOrAnEditionIsNotOpened() = runTest {
        answer("""{"entities":{"wd:Q1":{"uri":"wd:Q1","type":"work","labels":{"fr":"Le Comte de Monte-Cristo"}}}}""")
        answer("""{"entities":{"inv:e":{"uri":"inv:e","type":"edition"}}}""")
        for (uri in listOf("wd:Q1", "inv:e")) {
            try {
                repository.editableEntity(uri)
                fail("expected a failure for $uri")
            } catch (_: NetworkError.BadResponse) {
            }
        }
    }

    // Saving

    @Test
    fun aPersonToCreateGoesFirstThenEachClaimThenTheLabels() = runTest {
        answer("""{"entity":{"uri":"inv:illustrator"}}""")
        ok()
        ok()
        ok()
        val start: EntityEdit = opened()
        val edit: EntityEdit = start
            .copy(
                properties = start.properties
                    .add(EditionEntityValue(label = "Paul Martin"), WorkProperties.roles[1])
                    .setLiteral(ClaimLiteral.Text("wd:Q1004"), WorkProperties.Type),
            )
            .addingLabel("en")
            .withLabel("en", "Fireflies")

        val result: EntitySaveResult = repository.saveEntity(edit)

        val requests: List<RecordedRequest> = requests()
        assertEquals(
            listOf("/api/entities", "/api/entities/update-claim", "/api/entities/update-claim", "/api/entities/update-label"),
            requests.map { it.url.encodedPath },
        )
        assertEquals(EditionClaimUpdate(workUri, "wdt:P31", ClaimLiteral.Text("wd:Q7725634"), ClaimLiteral.Text("wd:Q1004")), claim(requests[1]))
        assertEquals(EditionClaimUpdate(workUri, "wdt:P110", null, ClaimLiteral.Text("inv:illustrator")), claim(requests[2]))
        assertEquals(EntityLabelUpdate(workUri, "en", "Fireflies"), label(requests[3]))
        val saved: EntityEdit = (result as? EntitySaveResult.Saved ?: return@runTest fail("expected a success")).edit
        assertFalse(saved.hasChanges)
    }

    @Test
    fun aRefusalHalfwayKeepsWhatLandedAndTheRetrySendsOnlyTheRest() = runTest {
        ok()
        answer("""{"status_verbose":"invalid value"}""", code = 400)
        val start: EntityEdit = opened()
        val edit: EntityEdit = start
            .copy(properties = start.properties.remove(setOf(0), WorkProperties.Author).setLiteral(ClaimLiteral.Text("3"), WorkProperties.SeriesOrdinal))
            .withLabel("fr", "Lucioles, quinze fictions")

        val failed: EntitySaveResult.Failed = repository.saveEntity(edit) as? EntitySaveResult.Failed ?: return@runTest fail("expected a failure")

        assertEquals(CreateBookFailure.Refused, failed.failure)
        assertEquals(listOf("wdt:P1545"), failed.edit.claimUpdates.map { it.property })
        assertEquals(listOf("Lucioles, quinze fictions"), failed.edit.labelUpdates.map { it.value })

        ok()
        ok()
        val retried: EntitySaveResult = repository.saveEntity(failed.edit)

        val requests: List<RecordedRequest> = requests()
        assertEquals(4, requests.size)
        assertEquals(EditionClaimUpdate(workUri, "wdt:P50", ClaimLiteral.Text("inv:lucie"), null), claim(requests[0]))
        // The author's removal is not sent again: only the rank, then the title.
        assertEquals(EditionClaimUpdate(workUri, "wdt:P1545", null, ClaimLiteral.Text("3")), claim(requests[2]))
        assertEquals(EntityLabelUpdate(workUri, "fr", "Lucioles, quinze fictions"), label(requests[3]))
        assertFalse((retried as? EntitySaveResult.Saved ?: return@runTest fail("expected a success")).edit.hasChanges)
    }

    private companion object {
        const val CLIENT_HEADER: String = "X-Test-Client"
    }
}
