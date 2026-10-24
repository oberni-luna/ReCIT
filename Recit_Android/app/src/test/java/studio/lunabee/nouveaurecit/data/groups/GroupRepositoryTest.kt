package studio.lunabee.nouveaurecit.data.groups

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.data.GroupRepository
import studio.lunabee.nouveaurecit.network.ApiService

/**
 * `GroupModelTests`: the groups against a local server. Every request is redirected from
 * inventaire.io to it, so nothing here touches the network.
 */
class GroupRepositoryTest {
    private lateinit var server: MockWebServer
    private lateinit var repository: GroupRepository
    private val ledger: InMemoryGroupRequestLedger = InMemoryGroupRequestLedger()
    private val people: RecordingGroupPeople = RecordingGroupPeople()
    private val myUserId: MutableStateFlow<String?> = MutableStateFlow("me")

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
        repository = GroupRepository(api = ApiService(client), people = people, ledger = ledger, myUserId = myUserId)
    }

    @After
    fun tearDown() {
        server.close()
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    private fun groupJson(id: String, name: String = id, admins: String = "", members: String = "", invited: String = "", requested: String = ""): String =
        """{"_id":"$id","name":"$name","admins":[$admins],"members":[$members],"invited":[$invited],"declined":[],"requested":[$requested]}"""

    private fun person(id: String, invitor: String? = null): String =
        """{"user":"$id","invitor":${invitor?.let { "\"$it\"" } ?: "null"},"timestamp":1}"""

    @Test
    fun aSyncKeepsTheGroupsByRoleAndNamesTheirPeople() = runTest {
        answer(
            """{"groups":[${groupJson("a", "Polars", admins = person("me"), requested = person("r"))},${groupJson("b", "Voisins", admins = person("x"), invited = person("me", invitor = "x"))}]}""",
        )
        repository.syncMyGroups("me")

        val groups: MyGroups = repository.myGroups.first()
        assertEquals(listOf("a"), groups.mine.map { it.id })
        assertEquals(listOf("b"), groups.invitations.map { it.id })
        assertEquals(2, groups.pendingCount)
        assertTrue(repository.hasLoaded.value)
        assertEquals(setOf("me", "r", "x"), people.fetched)
        assertEquals("/api/groups", server.takeRequest().url.encodedPath)
    }

    @Test
    fun aRequestStillWaitingIsReadBackAtTheNextSync() = runTest {
        ledger.add("c", "me")
        answer("""{"groups":[]}""")
        answer("""{"group":${groupJson("c", admins = person("x"), requested = person("me"))},"users":[{"_id":"x","username":"Xavier"}]}""")
        repository.syncMyGroups("me")

        assertEquals(listOf("c"), repository.myGroups.first().sentRequests.map { it.id })
        assertEquals(listOf("x"), people.stored.map { it.id })
        server.takeRequest()
        val byId: RecordedRequest = server.takeRequest()
        assertEquals("/api/groups/by-id", byId.url.encodedPath)
        assertEquals("c", byId.url.queryParameter("id"))
        assertEquals(setOf("c"), ledger.ids("me"))
    }

    @Test
    fun anAnsweredOrVanishedRequestIsForgotten() = runTest {
        ledger.add("accepted", "me")
        ledger.add("gone", "me")
        answer("""{"groups":[]}""")
        answer("""{"group":${groupJson("accepted", admins = person("x"), members = person("me"))},"users":[]}""")
        answer("""{"status":404}""", code = 404)
        repository.syncMyGroups("me")

        // Accepted, `/api/groups` will name it from now on; deleted, there is nothing left to wait on.
        assertTrue(ledger.ids("me").isEmpty())
    }

    @Test
    fun aRequestWhoseReadFailedIsKeptAsItWas() = runTest {
        ledger.add("c", "me")
        answer("""{"groups":[]}""")
        answer("""{"group":${groupJson("c", admins = person("x"), requested = person("me"))},"users":[]}""")
        repository.syncMyGroups("me")

        answer("""{"groups":[]}""")
        answer("oops", code = 500)
        repository.syncMyGroups("me")

        assertEquals(listOf("c"), repository.myGroups.first().sentRequests.map { it.id })
        assertEquals(setOf("c"), ledger.ids("me"))
    }

    @Test
    fun aGroupTheSyncNoLongerNamesLeavesMyGroupsButStaysReadable() = runTest {
        answer("""{"groups":[${groupJson("a", admins = person("x"), members = person("me"))}]}""")
        repository.syncMyGroups("me")
        answer("""{"groups":[]}""")
        repository.syncMyGroups("me")

        assertTrue(repository.myGroups.first().isEmpty)
        val left: ReaderGroup? = repository.observeGroup("a").first()
        assertEquals(listOf("x"), left?.admins?.map { it.user })
        assertNull(left?.role(of = "me"))
    }

    @Test
    fun aSyncThatOutlivesItsAccountWritesNothing() = runTest {
        answer("""{"groups":[${groupJson("a", admins = person("me"))}]}""")
        myUserId.value = "someone else"
        try {
            repository.syncMyGroups("me")
            fail("expected a failure")
        } catch (_: IllegalStateException) {
        }
        assertTrue(repository.groups.value.isEmpty())
        assertFalse(repository.hasLoaded.value)
    }

    @Test
    fun aGroupOpenedFromASearchIsReadAndKeptOutOfMine() = runTest {
        answer("""{"group":${groupJson("s", admins = person("x"))},"users":[{"_id":"x","username":"Xavier"}]}""")
        val group: ReaderGroup = repository.fetchGroup("s")

        assertEquals("s", group.id)
        assertEquals(group, repository.observeGroup("s").first())
        assertTrue(repository.myGroups.first().isEmpty)
    }

    @Test
    fun signingOutForgetsTheGroups() = runTest {
        answer("""{"groups":[${groupJson("a", admins = person("me"))}]}""")
        repository.syncMyGroups("me")
        repository.reset()

        assertTrue(repository.groups.value.isEmpty())
        assertFalse(repository.hasLoaded.value)
    }
}
