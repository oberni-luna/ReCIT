package studio.lunabee.nouveaurecit.data.shelves

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
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.network.ApiService
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/**
 * `ShelfModelAddItemsTests`: « Ajouter N livres » against a local server. Every request is redirected from
 * inventaire.io to it, so nothing here touches the network; the store is a map.
 */
class ShelfMembershipTest {
    private lateinit var server: MockWebServer
    private lateinit var membership: ShelfMembership
    private val store: InMemoryShelfMembershipStore = InMemoryShelfMembershipStore(
        shelves = mapOf("s" to listOf("a")),
        items = setOf("a", "b", "c"),
    )
    private val reporter: ErrorReporter = ErrorReporter()
    private val errors: MutableList<Throwable> = CopyOnWriteArrayList()

    /** The requests run on OkHttp's thread and come back unconfined: a test joins the job the write returns. */
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        val client: OkHttpClient = OkHttpClient.Builder()
            .addInterceptor { chain ->
                val redirected: HttpUrl = chain.request().url.newBuilder().scheme("http").host(server.hostName).port(server.port).build()
                chain.proceed(chain.request().newBuilder().url(redirected).build())
            }
            .build()
        scope.launch { reporter.failures.collect { errors += it } }
        membership = ShelfMembership(ApiService(client), store, OptimisticRunner(scope, reporter))
    }

    @After
    fun tearDown() {
        scope.cancel()
        server.close()
    }

    /** The reporter's collector resumes on whichever thread reported: wait for it, in real time. */
    private suspend fun awaitErrors(count: Int) = withContext(Dispatchers.Default) {
        withTimeout(2_000) { while (errors.size < count) delay(5) }
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    @Test
    fun theNewBooksGoOnTheShelfAtOnceInOneAddItemsRequest() = runTest {
        answer("""{"shelves":{"s":{"_id":"s","items":["a","b","c"]}}}""")

        val job: Job? = membership.add("s", listOf("a", "b", "c", "b"))

        // Linked before the request was sent, and only the books not there yet.
        assertEquals(listOf(listOf("b", "c")), store.linked)
        assertNotNull(job)
        job?.join()
        assertEquals(1, server.requestCount)
        val request: RecordedRequest = server.takeRequest()
        assertEquals("POST", request.method)
        assertEquals("/api/shelves", request.url.encodedPath)
        assertEquals("add-items", request.url.queryParameter("action"))
        assertEquals(
            JsonObject(mapOf("id" to JsonPrimitive("s"), "items" to JsonArray(listOf(JsonPrimitive("b"), JsonPrimitive("c"))))),
            Json.parseToJsonElement(request.body?.utf8().orEmpty()).jsonObject,
        )
        assertEquals(listOf("a", "b", "c"), store.itemIdsNow("s"))
        assertEquals(0, errors.size)
    }

    @Test
    fun aRefusalTakesTheBooksOffAgainAndSaysSo() = runTest {
        answer("nope", code = 400)

        membership.add("s", listOf("b", "c"))?.join()

        assertEquals(listOf("a"), store.itemIdsNow("s"))
        awaitErrors(1)
        assertEquals(1, errors.size)
    }

    @Test
    fun aBookGoneFromTheStoreDoesNotKeepTheOthersOnTheShelf() = runTest {
        answer("nope", code = 400)
        // Only the étagère is checked before the revert: « b » missing must not cancel the revert of « c ».
        store.items = setOf("a", "c")

        membership.add("s", listOf("b", "c"))?.join()

        assertEquals(listOf("a"), store.itemIdsNow("s"))
    }

    @Test
    fun booksAllOnTheShelfAlreadySendNothing() = runTest {
        val job: Job? = membership.add("s", listOf("a"))

        assertNull(job)
        assertEquals(emptyList<List<String>>(), store.linked)
        assertEquals(0, server.requestCount)
    }
}

/** [ShelfMembershipStore] in memory: the étagères' books in order, and every link the writes made. */
private class InMemoryShelfMembershipStore(shelves: Map<String, List<String>>, @Volatile var items: Set<String>) : ShelfMembershipStore {
    private val held: MutableMap<String, List<String>> = ConcurrentHashMap(shelves)
    val linked: MutableList<List<String>> = CopyOnWriteArrayList()

    fun itemIdsNow(shelfId: String): List<String> = held[shelfId].orEmpty()

    override suspend fun itemIds(shelfId: String): List<String> = itemIdsNow(shelfId)

    override suspend fun link(shelfId: String, itemIds: List<String>) {
        linked.add(itemIds)
        held[shelfId] = (itemIdsNow(shelfId) + itemIds).distinct()
    }

    override suspend fun unlink(shelfId: String, itemIds: List<String>) {
        held[shelfId] = itemIdsNow(shelfId) - itemIds.toSet()
    }

    override suspend fun hasShelf(shelfId: String): Boolean = shelfId in held

    override suspend fun hasItem(itemId: String): Boolean = itemId in items

    override suspend fun replaceItems(shelfId: String, serverItemIds: List<String>) {
        if (shelfId in held) held[shelfId] = serverItemIds.filter { it in items }
    }
}
