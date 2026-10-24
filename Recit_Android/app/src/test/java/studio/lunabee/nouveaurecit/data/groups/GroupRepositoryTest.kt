package studio.lunabee.nouveaurecit.data.groups

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
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
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.GroupRepository
import studio.lunabee.nouveaurecit.data.OptimisticRunner
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
    private val reporter: ErrorReporter = ErrorReporter()
    private val errors: MutableList<Throwable> = mutableListOf()

    /** The requests run on OkHttp's thread and come back unconfined: a test joins the job a gesture returns. */
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
        repository = GroupRepository(
            api = ApiService(client),
            people = people,
            ledger = ledger,
            runner = OptimisticRunner(scope, reporter),
            errorReporter = reporter,
            myUserId = myUserId,
        )
    }

    @After
    fun tearDown() {
        scope.cancel()
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

    private suspend fun syncOne(json: String) {
        answer("""{"groups":[$json]}""")
        repository.syncMyGroups("me")
        server.takeRequest()
    }

    @Test
    fun aGestureIsShownAtOnceAndSentAsAPutOnItsOwnPath() = runTest {
        syncOne(groupJson("a", admins = person("x"), invited = person("me", invitor = "x")))
        answer("""{"ok":true}""")
        val job: Job? = repository.perform(GroupAction.Accept, "a")

        assertEquals(GroupRole.Member, repository.groups.value.getValue("a").role(of = "me"))
        job?.join()
        val request: RecordedRequest = server.takeRequest()
        assertEquals("PUT", request.method)
        assertEquals("/api/groups/accept", request.url.encodedPath)
        assertEquals("""{"group":"a"}""", request.body?.utf8())
        assertEquals(GroupRole.Member, repository.groups.value.getValue("a").role(of = "me"))
    }

    @Test
    fun aGestureAboutSomeoneElseNamesThem() = runTest {
        syncOne(groupJson("a", admins = person("me"), requested = person("r")))
        answer("""{"ok":true}""")
        repository.perform(GroupAction.AcceptRequest, "a", target = "r")?.join()

        assertEquals(GroupRole.Member, repository.groups.value.getValue("a").role(of = "r"))
        assertEquals("""{"group":"a","user":"r"}""", server.takeRequest().body?.utf8())
    }

    @Test
    fun aRefusedGesturePutsTheGroupBackAndSaysSo() = runTest {
        syncOne(groupJson("a", admins = person("x"), invited = person("me", invitor = "x")))
        answer("nope", code = 400)
        repository.perform(GroupAction.Decline, "a")?.join()

        assertEquals(GroupRole.Invited, repository.groups.value.getValue("a").role(of = "me"))
        assertEquals(1, errors.size)
    }

    @Test
    fun aGestureTheServerWouldRefuseIsNeitherShownNorSent() = runTest {
        syncOne(groupJson("a", admins = person("me"), members = person("m")))
        val job: Job? = repository.perform(GroupAction.Leave, "a")

        assertNull(job)
        assertEquals(GroupRole.Admin, repository.groups.value.getValue("a").role(of = "me"))
        assertTrue(errors.single() is GroupTransitionError.LastAdmin)
        // The sync's request, and nothing since.
        assertEquals(1, server.requestCount)
    }

    @Test
    fun aRequestStillWaitingIsRememberedAndACancelledOneForgotten() = runTest {
        answer("""{"group":${groupJson("s", admins = person("x"))},"users":[]}""")
        repository.fetchGroup("s")
        answer("""{"ok":true}""")
        repository.perform(GroupAction.Request, "s")?.join()

        assertEquals(listOf("s"), repository.myGroups.first().sentRequests.map { it.id })
        assertEquals(setOf("s"), ledger.ids("me"))

        answer("""{"ok":true}""")
        repository.perform(GroupAction.CancelRequest, "s")?.join()
        assertTrue(ledger.ids("me").isEmpty())
        assertTrue(repository.myGroups.first().isEmpty)
    }

    @Test
    fun aRequestToAnOpenGroupLetsMeInAndNeedsNoRemembering() = runTest {
        answer("""{"group":{"_id":"o","name":"Ouvert","open":true,"admins":[${person("x")}],"members":[]},"users":[]}""")
        repository.fetchGroup("o")
        answer("""{"ok":true}""")
        repository.perform(GroupAction.Request, "o")?.join()

        assertEquals(listOf("o"), repository.myGroups.first().mine.map { it.id })
        assertTrue(ledger.ids("me").isEmpty())
    }

    @Test
    fun theSearchKeepsTheServersRanking() = runTest {
        answer(
            """{"results":[{"id":"b","label":"Polars","_score":1.5},{"id":"a","label":"Polar club","description":"Le jeudi","image":"/img/groups/abc","_score":3.2}]}""",
        )
        val results: List<GroupSearchResult> = repository.searchGroups("  polar & co ")

        assertEquals(listOf("a", "b"), results.map { it.id })
        assertEquals("https://inventaire.io/img/groups/abc", results.first().pictureUrl)
        val request: RecordedRequest = server.takeRequest()
        assertEquals("groups", request.url.queryParameter("types"))
        assertEquals("polar & co", request.url.queryParameter("search"))
        assertTrue(repository.searchGroups("   ").isEmpty())
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
