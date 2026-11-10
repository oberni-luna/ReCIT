package studio.lunabee.nouveaurecit.data.inventory

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import mockwebserver3.Dispatcher
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.network.ApiService
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

/**
 * `InventoryModelTests`' text writes (feature 0080): the Commentaire and the Note privée against a
 * local server, the store in memory.
 */
class InventoryItemTextWriterTest {
    private lateinit var server: MockWebServer
    private lateinit var writer: InventoryItemTextWriter
    private val store: InMemoryInventoryItemTextStore = InMemoryInventoryItemTextStore()
    private val reporter: ErrorReporter = ErrorReporter()
    private val errors: MutableList<Throwable> = CopyOnWriteArrayList()

    /** The requests run on OkHttp's thread and come back unconfined: a test joins the job a write returns. */
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)

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
        scope.launch { reporter.failures.collect { errors += it } }
        store.put("i1", details = "Superbe", notes = "Prêté à Léa")
        writer = InventoryItemTextWriter(ApiService(client), store, OptimisticRunner(scope, reporter))
    }

    @After
    fun tearDown() {
        scope.cancel()
        server.close()
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    /** The reporter's collector resumes on whichever thread reported: wait for it, in real time. */
    private suspend fun awaitErrors(count: Int) = withContext(Dispatchers.Default) {
        withTimeout(2_000) { while (errors.size < count) delay(5) }
    }

    @Test
    fun aNoteIsStoredAtOnceAndSentAsNotesWithTheCommentaireUntouched() = runTest {
        answer("""{"ok":true}""")
        val job: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "À relire")

        assertEquals("À relire", store.text("i1", InventoryItemTextAttribute.Notes))
        job?.join()
        val request: RecordedRequest = server.takeRequest()
        assertEquals("PUT", request.method)
        assertEquals("/api/items/bulk-update", request.url.encodedPath)
        assertEquals("""{"ids":["i1"],"attribute":"notes","value":"À relire"}""", request.body?.utf8())
        assertEquals("Superbe", store.text("i1", InventoryItemTextAttribute.Details))
        assertEquals(1, server.requestCount)
    }

    @Test
    fun theCommentaireIsSentAsDetails() = runTest {
        answer("""{"ok":true}""")
        writer.write("i1", InventoryItemTextAttribute.Details, "Bouleversant")?.join()

        assertEquals("""{"ids":["i1"],"attribute":"details","value":"Bouleversant"}""", server.takeRequest().body?.utf8())
        assertEquals("Prêté à Léa", store.text("i1", InventoryItemTextAttribute.Notes))
    }

    @Test
    fun anUnchangedTextOrAGoneItemSendsNothing() = runTest {
        assertNull(writer.write("i1", InventoryItemTextAttribute.Notes, "Prêté à Léa"))
        assertNull(writer.write("gone", InventoryItemTextAttribute.Notes, "Note"))
        assertEquals(0, server.requestCount)
    }

    @Test
    fun aRefusedNoteGoesBackAndIsReported() = runTest {
        answer("""{"ok":false}""")
        writer.write("i1", InventoryItemTextAttribute.Notes, "Refusée")?.join()

        assertEquals("Prêté à Léa", store.text("i1", InventoryItemTextAttribute.Notes))
        awaitErrors(1)
        assertEquals(1, errors.size)
    }

    @Test
    fun aStaleRefusalKeepsTheNoteTypedAfterIt() = runTest {
        answer("oops", code = 500)
        answer("""{"ok":true}""")
        val first: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Première")
        val second: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Seconde")
        first?.join()
        second?.join()

        assertEquals("Seconde", store.text("i1", InventoryItemTextAttribute.Notes))
        awaitErrors(1)
        assertEquals(2, server.requestCount)
    }

    @Test
    fun twoRefusalsInARowPutBackTheLastAcceptedNote() = runTest {
        answer("oops", code = 500)
        answer("oops", code = 500)
        val first: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Première")
        val second: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Seconde")
        first?.join()
        second?.join()

        assertEquals("Prêté à Léa", store.text("i1", InventoryItemTextAttribute.Notes))
        awaitErrors(2)
        assertEquals(2, server.requestCount)
    }

    @Test
    fun aRefusalAfterAnAcceptedNotePutsTheAcceptedOneBack() = runTest {
        answer("""{"ok":true}""")
        answer("oops", code = 500)
        val first: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Première")
        val second: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Seconde")
        first?.join()
        second?.join()

        assertEquals("Première", store.text("i1", InventoryItemTextAttribute.Notes))
        awaitErrors(1)
    }

    @Test
    fun aSecondWriteLeavesOnlyOnceTheFirstIsAnswered() = runTest {
        val firstAnswered: AtomicBoolean = AtomicBoolean(false)
        val secondSawFirstAnswered: AtomicBoolean = AtomicBoolean(false)
        val values: MutableList<String> = CopyOnWriteArrayList()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val body: String = request.body?.utf8().orEmpty()
                values += body
                if (values.size == 1) {
                    // Long enough for a second request sent without waiting to arrive meanwhile.
                    Thread.sleep(300)
                    firstAnswered.set(true)
                } else {
                    secondSawFirstAnswered.set(firstAnswered.get())
                }
                return MockResponse.Builder().code(200).body("""{"ok":true}""").build()
            }
        }
        val first: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Première")
        val second: Job? = writer.write("i1", InventoryItemTextAttribute.Notes, "Seconde")

        assertEquals("Seconde", store.text("i1", InventoryItemTextAttribute.Notes))
        first?.join()
        second?.join()
        assertEquals(2, values.size)
        assertTrue(values[0].contains("Première"))
        assertTrue(values[1].contains("Seconde"))
        assertTrue(secondSawFirstAnswered.get())
    }
}
