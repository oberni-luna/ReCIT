package studio.lunabee.nouveaurecit.data.user

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.OkHttpClient
import okio.Buffer
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import java.io.File
import kotlin.time.Duration.Companion.milliseconds

/**
 * Saving « Modifier le profil » against a local server: every call — inventaire.io's and gravatar.com's —
 * is redirected to it, so nothing here touches the network or a real account.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ProfileRepositoryTest {
    private lateinit var server: MockWebServer
    private lateinit var client: OkHttpClient
    private lateinit var store: RecordingStore

    /** My user as the store holds it, and the virtual time of each write onto it. */
    private class RecordingStore(var me: UserEntity, private val clock: () -> Long) : MyProfileStore {
        val writes: MutableList<Long> = mutableListOf()

        override suspend fun updateMyUser(transform: (UserEntity) -> UserEntity) {
            me = transform(me)
            writes += clock()
        }
    }

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        client = OkHttpClient.Builder()
            .addInterceptor { chain ->
                val redirected = chain.request().url.newBuilder().scheme("http").host(server.hostName).port(server.port).build()
                chain.proceed(chain.request().newBuilder().url(redirected).build())
            }
            .build()
    }

    @After
    fun tearDown() {
        server.close()
    }

    private fun TestScope.repository(): ProfileRepository {
        store = RecordingStore(UserEntity(id = "u1", username = "lectrice", bio = "Romans noirs", avatarUrl = null)) { currentTime }
        val pacer = RequestPacer(interval = 1_100.milliseconds, timeSource = testScheduler.timeSource)
        return ProfileRepository(api = ApiService(client), publicClient = client, pacer = pacer, store = store)
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    private fun picture(): File = File.createTempFile("avatar", ".jpg").apply {
        writeBytes(byteArrayOf(1, 2, 3))
        deleteOnExit()
    }

    private fun RecordedRequest.json(): JsonElement = Json.parseToJsonElement(body!!.utf8())

    private fun update(attribute: String, value: String): JsonElement =
        Json.parseToJsonElement("""{"attribute":"$attribute","value":$value}""")

    @Test
    fun thePictureIsUploadedThenEachChangeIsPutInOrderAndWrittenOntoMyUser() = runTest {
        val repository: ProfileRepository = repository()
        val hash: String = "a".repeat(40)
        answer("""{"avatar":"/img/users/$hash"}""")
        answer("""{"ok":true}""")
        answer("""{"ok":true}""")

        repository.saveProfile(listOf(ProfileChange.Picture(picture().path), ProfileChange.Bio("Polars")))

        val upload: RecordedRequest = server.takeRequest()
        assertEquals("POST", upload.method)
        assertEquals("/api/images/upload", upload.url.encodedPath)
        assertEquals("users", upload.url.queryParameter("container"))
        assertTrue(upload.body!!.utf8().contains("""name="avatar"; filename="avatar.jpg""""))

        val first: RecordedRequest = server.takeRequest()
        assertEquals("PUT", first.method)
        assertEquals("/api/user", first.url.encodedPath)
        assertEquals(update("picture", "\"/img/users/$hash\""), first.json())

        val second: RecordedRequest = server.takeRequest()
        assertEquals("PUT", second.method)
        assertEquals(update("bio", "\"Polars\""), second.json())

        assertEquals("https://inventaire.io/img/users/$hash", store.me.avatarUrl)
        assertEquals("Polars", store.me.bio)
        assertEquals(2, store.writes.size)
        assertTrue("the two PUTs leave at least a second apart", store.writes[1] - store.writes[0] >= 1_000)
    }

    @Test
    fun aSecondPutRefusedKeepsTheFirstAndNamesTheRefusedAttribute() = runTest {
        val repository: ProfileRepository = repository()
        answer("""{"ok":true}""")
        answer("""{"status":400,"status_verbose":"invalid value"}""", code = 400)
        val changes: List<ProfileChange> = listOf(
            ProfileChange.Username("liseuse"),
            ProfileChange.Bio("Polars"),
            ProfileChange.Position(Coordinates(48.85, 2.35)),
        )

        val failure: ProfileSaveFailure = try {
            repository.saveProfile(changes)
            fail("The server refused the bio")
            return@runTest
        } catch (error: ProfileSaveFailure) {
            error
        }

        assertEquals(ProfileChange.Kind.Bio, failure.refused)
        assertEquals(listOf(ProfileChange.Username("liseuse")), failure.landed)
        assertTrue(failure.cause is NetworkError.BadStatus)
        assertEquals("liseuse", store.me.username)
        assertEquals("Romans noirs", store.me.bio)
        assertEquals(2, server.requestCount)
    }

    @Test
    fun aRetrySendsOnlyWhatHadNotLanded() = runTest {
        val repository: ProfileRepository = repository()
        val draft: ProfileDraft = ProfileDraft(ProfileDraft.Saved(username = "lectrice", bio = "", position = null, hasPicture = false))
            .copy(username = "liseuse", bio = "Polars")
            .placed(Coordinates(48.853_4, 2.348_8))
        answer("""{"ok":true}""")
        answer("""{"status":429}""", code = 429)

        val retry: ProfileDraft = try {
            repository.saveProfile(draft.changes)
            fail("The server refused the bio")
            return@runTest
        } catch (failure: ProfileSaveFailure) {
            draft.markLanded(failure.landed)
        }
        server.takeRequest()
        server.takeRequest()
        answer("""{"ok":true}""")
        answer("""{"ok":true}""")

        repository.saveProfile(retry.changes)

        assertEquals(update("bio", "\"Polars\""), server.takeRequest().json())
        assertEquals(update("position", "[48.85,2.35]"), server.takeRequest().json())
        assertEquals(4, server.requestCount)
        assertEquals(48.85, store.me.latitude)
        assertEquals(2.35, store.me.longitude)
    }

    @Test
    fun removingThePictureSendsAnExplicitNullAndUploadsNothing() = runTest {
        val repository: ProfileRepository = repository()
        store.me = store.me.copy(avatarUrl = "https://inventaire.io/img/users/${"b".repeat(40)}")
        answer("""{"ok":true}""")

        repository.saveProfile(listOf(ProfileChange.Picture(null)))

        val request: RecordedRequest = server.takeRequest()
        assertEquals("/api/user", request.url.encodedPath)
        assertEquals("""{"attribute":"picture","value":null}""", request.body!!.utf8())
        assertNull(store.me.avatarUrl)
    }

    @Test
    fun anAddressWithoutGravatarHasNone() = runTest {
        val repository: ProfileRepository = repository()
        answer("""{"url":"https://www.gravatar.com/avatar/0123?d=404&s=500"}""")
        answer("Not Found", code = 404)

        assertNull(repository.gravatarImage())

        assertEquals("/api/images/gravatar", server.takeRequest().url.encodedPath)
        val download: RecordedRequest = server.takeRequest()
        assertEquals("/avatar/0123", download.url.encodedPath)
        assertEquals("404", download.url.queryParameter("d"))
    }

    @Test
    fun aGravatarIsDownloadedAsBytes() = runTest {
        val repository: ProfileRepository = repository()
        answer("""{"url":"https://www.gravatar.com/avatar/0123?d=404&s=500"}""")
        server.enqueue(MockResponse.Builder().code(200).body(Buffer().write(byteArrayOf(9, 8, 7))).build())

        assertArrayEquals(byteArrayOf(9, 8, 7), repository.gravatarImage())
    }
}
