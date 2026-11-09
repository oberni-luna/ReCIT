package studio.lunabee.nouveaurecit.data.user

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import mockwebserver3.RecordedRequest
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.UserDto
import studio.lunabee.nouveaurecit.ui.profile.account.ChangeEmailViewModel
import java.util.Collections
import kotlin.time.Duration.Companion.milliseconds

/**
 * « Compte et connexion » against a local server: switches written at once and alone to go back, the
 * address and the password server first. Nothing here touches the network or a real account.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AccountRepositoryTest {
    private lateinit var server: MockWebServer
    private lateinit var store: RecordingStore
    private lateinit var reported: MutableList<Throwable>

    /** The virtual time at which each request left, read by the client on its way out. */
    private val sentAt: MutableList<Long> = Collections.synchronizedList(mutableListOf())

    private class RecordingStore(var me: UserEntity) : MyProfileStore {
        override suspend fun updateMyUser(transform: (UserEntity) -> UserEntity) {
            me = transform(me)
        }
    }

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.close()
    }

    private fun TestScope.repository(): AccountRepository {
        val client: OkHttpClient = OkHttpClient.Builder()
            .addInterceptor { chain ->
                sentAt += testScheduler.currentTime
                val redirected: HttpUrl = chain.request().url.newBuilder().scheme("http").host(server.hostName).port(server.port).build()
                chain.proceed(chain.request().newBuilder().url(redirected).build())
            }
            .build()
        val api: ApiService = ApiService(client)
        store = RecordingStore(UserEntity(id = "u1", username = "lectrice", email = "l@example.org"))
        val pacer: RequestPacer = RequestPacer(interval = 1_100.milliseconds, timeSource = testScheduler.timeSource)
        val reporter: ErrorReporter = ErrorReporter()
        reported = mutableListOf()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { reporter.failures.collect { reported += it } }
        val repository: AccountRepository = AccountRepository(
            api = api,
            profile = ProfileRepository(api = api, publicClient = client, pacer = pacer, store = store),
            runner = OptimisticRunner(this, reporter),
            store = store,
        )
        repository.take(
            UserDto(id = "u1", username = "lectrice", email = "l@example.org", language = "fr", validEmail = true, fediversable = false),
        )
        return repository
    }

    private fun answer(body: String, code: Int = 200) {
        server.enqueue(MockResponse.Builder().code(code).body(body).build())
    }

    private fun RecordedRequest.json(): JsonElement = Json.parseToJsonElement(body!!.utf8())

    private fun update(attribute: String, value: String): JsonElement =
        Json.parseToJsonElement("""{"attribute":"$attribute","value":$value}""")

    private val AccountRepository.current: AccountSettings get() = settings.value ?: error("no settings held")

    @Test
    fun aSwitchMovesAtOnceAndSendsItsAttribute() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"ok":true}""")

        val write: Job? = repository.setFediversable(true)
        assertTrue("on before the server answers", repository.current.isFediversable)
        write?.join()

        val request: RecordedRequest = server.takeRequest()
        assertEquals("PUT", request.method)
        assertEquals("/api/user", request.url.encodedPath)
        assertEquals(update("fediversable", "true"), request.json())
        assertTrue(repository.current.isFediversable)
        assertTrue(reported.isEmpty())
    }

    @Test
    fun aRefusedSwitchGoesBackAloneAndIsReported() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"status":429}""", code = 429)
        answer("""{"ok":true}""")

        val first: Job? = repository.setFediversable(true)
        val second: Job? = repository.setAnonymizesContributions(false)
        first?.join()
        second?.join()

        assertFalse("the refused switch is back off", repository.current.isFediversable)
        assertFalse("the other one keeps its new value", repository.current.anonymizesContributions)
        assertEquals(1, reported.size)
        assertTrue(reported.single() is NetworkError.BadStatus)
        assertEquals(update("fediversable", "true"), server.takeRequest().json())
        assertEquals(update("settings.contributions.anonymize", "false"), server.takeRequest().json())
    }

    @Test
    fun twoSwitchesInARowLeaveASecondApart() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"ok":true}""")
        answer("""{"ok":true}""")

        val first: Job? = repository.setFediversable(true)
        val second: Job? = repository.setAnonymizesContributions(false)
        first?.join()
        second?.join()

        assertEquals(2, server.requestCount)
        assertEquals(2, sentAt.size)
        assertTrue("the second PUT waits for its slot: ${sentAt[1] - sentAt[0]} ms", sentAt[1] - sentAt[0] >= 1_000)
        assertTrue(reported.isEmpty())
    }

    @Test
    fun theLanguageIsWrittenAndTheSameOneSendsNothing() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"ok":true}""")

        assertNull(repository.setLanguage("fr"))
        repository.setLanguage("en")?.join()

        assertEquals(1, server.requestCount)
        assertEquals(update("language", "\"en\""), server.takeRequest().json())
        assertEquals("en", repository.current.language)
    }

    @Test
    fun aNewAddressIsHeldUnconfirmedOnceTheServerTookIt() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"ok":true}""")

        repository.changeEmail("nouvelle@example.org")

        assertEquals(update("email", "\"nouvelle@example.org\""), server.takeRequest().json())
        assertEquals("nouvelle@example.org", repository.current.email)
        assertFalse(repository.current.isEmailValidated)
        assertEquals("nouvelle@example.org", store.me.email)
    }

    @Test
    fun aRefusedAddressKeepsTheOldOneAndSaysWhy() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"status":400,"status_verbose":"this email is already used"}""", code = 400)

        val error: Exception = try {
            repository.changeEmail("prise@example.org")
            fail("The server refused the address")
            return@runTest
        } catch (error: NetworkError.BadStatus) {
            error
        }

        assertEquals("l@example.org", repository.current.email)
        assertTrue(repository.current.isEmailValidated)
        assertEquals("l@example.org", store.me.email)
        assertEquals(FieldAvailability.Outcome.Taken, ChangeEmailViewModel.refusal(error))
    }

    @Test
    fun theConfirmationIsAskedForAgain() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"ok":true}""")

        repository.resendEmailConfirmation()

        val request: RecordedRequest = server.takeRequest()
        assertEquals("POST", request.method)
        assertEquals("/api/auth/email-confirmation", request.url.encodedPath)
    }

    @Test
    fun thePasswordGoesUnderTheServersHyphenatedNames() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"ok":true}""")

        repository.changePassword(current = "ancien-secret", new = "nouveau-secret")

        val request: RecordedRequest = server.takeRequest()
        assertEquals("PUT", request.method)
        assertEquals("/api/auth/password", request.url.encodedPath)
        assertEquals(Json.parseToJsonElement("""{"old-password":"ancien-secret","new-password":"nouveau-secret"}"""), request.json())
    }

    @Test
    fun passwordRefusalsHaveTheirSentences() = runTest {
        val repository: AccountRepository = repository()
        answer("""{"status":400,"status_verbose":"invalid old-password"}""", code = 400)
        answer("""{"status":400,"status_verbose":"invalid new-password"}""", code = 400)
        answer("""{"status":429}""", code = 429)

        val reasons: List<PasswordChangeFailure.Reason> = List(3) {
            try {
                repository.changePassword(current = "ancien-secret", new = "nouveau-secret")
                fail("The server refused the password")
                return@runTest
            } catch (failure: PasswordChangeFailure) {
                failure.reason
            }
        }

        assertEquals(
            listOf(PasswordChangeFailure.Reason.WrongCurrentPassword, PasswordChangeFailure.Reason.Other, PasswordChangeFailure.Reason.Other),
            reasons,
        )
        assertEquals(R.string.change_password_failure_current, reasons[0].sentence)
        assertEquals(R.string.change_password_failure_other, reasons[1].sentence)
    }

    @Test
    fun signingOutEmptiesTheSettingsAndTheNextAccountShowsOnlyItsOwn() = runTest {
        val repository: AccountRepository = repository()

        repository.forget()
        assertNull(repository.settings.value)
        assertNull("nothing to write once forgotten", repository.setFediversable(true))

        repository.take(UserDto(id = "u2", username = "autre", email = "autre@example.org"))
        assertEquals("autre@example.org", repository.current.email)
        assertNull(repository.current.language)
        assertEquals(0, server.requestCount)
    }
}
