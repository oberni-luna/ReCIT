package studio.lunabee.nouveaurecit.data.groups

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
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
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.GroupRepository
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.network.ApiService
import java.io.File
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * `GroupPictureTests`: a group's photo, written server first from « Réglages du groupe », against a
 * local server — every request is redirected from inventaire.io to it.
 */
class GroupPictureTest {
    @get:Rule
    val folder: TemporaryFolder = TemporaryFolder()

    private lateinit var server: MockWebServer
    private lateinit var repository: GroupRepository
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
        repository = GroupRepository(
            api = ApiService(client),
            people = RecordingGroupPeople(),
            ledger = InMemoryGroupRequestLedger(),
            runner = OptimisticRunner(scope, reporter),
            errorReporter = reporter,
            myUserId = MutableStateFlow("me"),
        )
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

    /** My group « Club », its photo at [OLD_PATH], as the sync left it. */
    private suspend fun syncClub() {
        answer(
            """{"groups":[{"_id":"g","name":"Club","picture":"$OLD_PATH","admins":[{"user":"me","invitor":null,"timestamp":1}],"members":[]}]}""",
        )
        repository.syncMyGroups("me")
        server.takeRequest()
    }

    /** A photo picked and reduced, as `CoverPhoto.reduce` leaves it in the cache. */
    private fun pickedPhoto(): GroupPictureEdit.Replaced {
        val file: File = folder.newFile("cover.jpg").apply { writeBytes(byteArrayOf(1, 2, 3)) }
        return GroupPictureEdit.Replaced(file.absolutePath)
    }

    private fun club(): ReaderGroup = repository.groups.value.getValue("g")

    @Test
    fun aPickedPhotoIsUploadedIntoGroupsThenNamedThenShown() = runTest {
        syncClub()
        answer("""{"picture":"$NEW_PATH"}""")
        answer("""{"ok":true}""")

        repository.updatePicture(pickedPhoto(), "g")

        val upload: RecordedRequest = server.takeRequest()
        assertEquals("POST", upload.method)
        assertEquals("/api/images/upload", upload.url.encodedPath)
        assertEquals("groups", upload.url.queryParameter("container"))
        assertTrue(upload.body?.utf8().orEmpty().contains("""name="picture"; filename="group.jpg""""))
        val write: RecordedRequest = server.takeRequest()
        assertEquals("PUT", write.method)
        assertEquals("/api/groups/update-settings", write.url.encodedPath)
        assertEquals("""{"group":"g","attribute":"picture","value":"$NEW_PATH"}""", write.body?.utf8())
        assertEquals("https://inventaire.io$NEW_PATH", club().pictureUrl)
        assertTrue(errors.isEmpty())
    }

    @Test
    fun aRemovedPhotoSendsNullWithoutUploading() = runTest {
        syncClub()
        answer("""{"ok":true}""")

        repository.updatePicture(GroupPictureEdit.Removed, "g")

        val write: RecordedRequest = server.takeRequest()
        assertEquals("/api/groups/update-settings", write.url.encodedPath)
        assertEquals("""{"group":"g","attribute":"picture","value":null}""", write.body?.utf8())
        assertEquals(2, server.requestCount)
        assertNull(club().pictureUrl)
    }

    @Test
    fun anUntouchedPhotoSendsNothing() = runTest {
        syncClub()

        repository.updatePicture(GroupPictureEdit.Unchanged, "g")

        assertEquals(1, server.requestCount)
        assertEquals("https://inventaire.io$OLD_PATH", club().pictureUrl)
    }

    @Test
    fun aFailedUploadNamesNothingAndKeepsTheOldPhoto() = runTest {
        syncClub()
        answer("upload", code = 500)

        repository.updatePicture(pickedPhoto(), "g")

        assertEquals("/api/images/upload", server.takeRequest().url.encodedPath)
        assertEquals(2, server.requestCount)
        assertEquals("https://inventaire.io$OLD_PATH", club().pictureUrl)
        awaitErrors(1)
        assertEquals(1, errors.size)
    }

    @Test
    fun aRefusedPhotoKeepsTheOldOneAndSaysSo() = runTest {
        syncClub()
        answer("""{"picture":"$NEW_PATH"}""")
        answer("invalid picture", code = 400)

        repository.updatePicture(pickedPhoto(), "g")

        assertEquals(3, server.requestCount)
        assertEquals("https://inventaire.io$OLD_PATH", club().pictureUrl)
        awaitErrors(1)
        assertEquals(1, errors.size)
    }

    @Test
    fun aRefusedNameGivesBackTheNameAloneAndKeepsThePhotoThatLandedFirst() = runTest {
        syncClub()
        val nameMayAnswer: CountDownLatch = CountDownLatch(1)
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse = when {
                request.url.encodedPath == "/api/images/upload" -> MockResponse.Builder().body("""{"picture":"$NEW_PATH"}""").build()
                request.body?.utf8().orEmpty().contains(""""attribute":"name"""") -> {
                    nameMayAnswer.await(2, TimeUnit.SECONDS)
                    MockResponse.Builder().code(400).body("name").build()
                }
                else -> MockResponse.Builder().body("""{"ok":true}""").build()
            }
        }

        val rename: Job? = repository.update(GroupSetting.Name("Polars"), "g")
        repository.updatePicture(pickedPhoto(), "g")
        assertEquals("Polars", club().name)
        assertEquals("https://inventaire.io$NEW_PATH", club().pictureUrl)
        nameMayAnswer.countDown()
        rename?.join()

        assertEquals("Club", club().name)
        assertEquals("https://inventaire.io$NEW_PATH", club().pictureUrl)
        awaitErrors(1)
        assertEquals(1, errors.size)
    }

    @Test
    fun onlyAPickedPhotoOrASavedOneTakenAwayIsAChange() {
        val picked: GroupPictureEdit = GroupPictureEdit.Replaced("/cache/covers/cover.jpg")

        assertFalse(GroupPictureEdit.Unchanged.isChange(from = OLD_PATH))
        assertTrue(picked.isChange(from = null))
        assertTrue(GroupPictureEdit.Removed.isChange(from = OLD_PATH))
        assertFalse(GroupPictureEdit.Removed.isChange(from = null))
    }

    @Test
    fun theSlotShowsTheSavedPhotoUntilItIsReplacedOrTakenAway() {
        val picked: GroupPictureEdit = GroupPictureEdit.Replaced("/cache/covers/cover.jpg")

        assertTrue(GroupPictureEdit.Unchanged.showsPicture(savedPictureUrl = OLD_PATH))
        assertFalse(GroupPictureEdit.Unchanged.showsPicture(savedPictureUrl = null))
        assertTrue(picked.showsPicture(savedPictureUrl = null))
        assertFalse(GroupPictureEdit.Removed.showsPicture(savedPictureUrl = OLD_PATH))
    }

    private companion object {
        const val OLD_PATH: String = "/img/groups/old"
        const val NEW_PATH: String = "/img/groups/0123456789012345678901234567890123456789"
    }
}
