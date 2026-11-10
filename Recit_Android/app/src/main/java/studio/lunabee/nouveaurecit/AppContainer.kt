package studio.lunabee.nouveaurecit

import android.content.Context
import coil3.ImageLoader
import coil3.network.okhttp.OkHttpNetworkFetcherFactory
import java.util.concurrent.TimeUnit
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import okhttp3.OkHttpClient
import studio.lunabee.nouveaurecit.auth.AuthRepository
import studio.lunabee.nouveaurecit.auth.AuthService
import studio.lunabee.nouveaurecit.auth.KeystoreSessionVault
import studio.lunabee.nouveaurecit.auth.SessionCookieJar
import studio.lunabee.nouveaurecit.data.CoverWallRepository
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.GroupRepository
import studio.lunabee.nouveaurecit.data.InventoryRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.data.SearchRepository
import studio.lunabee.nouveaurecit.data.SessionCoordinator
import studio.lunabee.nouveaurecit.data.ShelfRepository
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.TransactionRepository
import studio.lunabee.nouveaurecit.data.UserPreferences
import studio.lunabee.nouveaurecit.data.UserRepository
import studio.lunabee.nouveaurecit.data.creation.EntityCreationRepository
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.groups.PreferencesGroupRequestLedger
import studio.lunabee.nouveaurecit.data.shelves.RoomShelfMembershipStore
import studio.lunabee.nouveaurecit.data.shelves.ShelfMembership
import studio.lunabee.nouveaurecit.data.sorting.SortSession
import studio.lunabee.nouveaurecit.data.user.ProfileRepository
import studio.lunabee.nouveaurecit.data.user.RequestPacer
import studio.lunabee.nouveaurecit.network.ApiService

/**
 * The composition root — `ReCIT.swift` plus `RootView`'s `@State` models. One instance per process,
 * built by [RecitApplication]. Every app-scoped repository lives here; screens reach them through
 * `LocalAppContainer` and their `ViewModel` factories.
 *
 * Two HTTP clients, as ADR 0008 asks: [sessionClient] carries the cookie jar, [publicClient] has none.
 */
class AppContainer(context: Context) {
    val applicationScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val cookieJar: SessionCookieJar = SessionCookieJar()

    /**
     * Every request names the app. Wikimedia Commons answers `403` to OkHttp's default
     * `okhttp/x.y` agent, which left every author portrait and Commons cover blank.
     */
    private val baseClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor { chain -> chain.proceed(chain.request().newBuilder().header("User-Agent", USER_AGENT).build()) }
        .build()

    val sessionClient: OkHttpClient = baseClient.newBuilder().cookieJar(cookieJar).build()
    val publicClient: OkHttpClient = baseClient

    val api: ApiService = ApiService(sessionClient)
    val publicApi: ApiService = ApiService(publicClient)

    val database: AppDatabase = AppDatabase.build(context)
    val preferences: UserPreferences = UserPreferences(context)

    val errorReporter: ErrorReporter = ErrorReporter()
    val syncStatus: SyncStatus = SyncStatus()
    val optimisticRunner: OptimisticRunner = OptimisticRunner(applicationScope, errorReporter)

    val auth: AuthRepository = AuthRepository(
        AuthService(
            sessionClient = sessionClient,
            publicClient = publicClient,
            jar = cookieJar,
            vault = KeystoreSessionVault(context, BuildConfig.SESSION_STORE_NAME),
        ),
    )

    val entities: EntityRepository = EntityRepository(api, database.entityDao())
    val users: UserRepository = UserRepository(api, database, optimisticRunner, preferences)

    /**
     * The one slot every `PUT /api/user` waits for: the server refuses a second write within a second of
     * the first (`minTimeBetweenRequests: 1000`), so they leave 1.1 s apart, whichever screen sends them.
     */
    val userUpdatePacer: RequestPacer = RequestPacer(interval = 1_100.milliseconds)

    /** « Modifier le profil » (feature 0055), server first. The Gravatar is downloaded without the session. */
    val profile: ProfileRepository = ProfileRepository(api, publicClient, userUpdatePacer, users)

    /** The groups are held in memory for the launch, their members in the store (feature 0046). */
    val groups: GroupRepository = GroupRepository(
        api = api,
        people = users,
        ledger = PreferencesGroupRequestLedger(preferences),
        runner = optimisticRunner,
        errorReporter = errorReporter,
        myUserId = users.myUserId,
    )
    val inventory: InventoryRepository = InventoryRepository(api, database, entities, optimisticRunner, syncStatus)
    val shelves: ShelfRepository = ShelfRepository(
        api = api,
        db = database,
        runner = optimisticRunner,
        membership = ShelfMembership(api, RoomShelfMembershipStore(database), optimisticRunner),
    )
    val lists: ListRepository = ListRepository(api, database, optimisticRunner, users.myUserId)
    val search: SearchRepository = SearchRepository(api)

    /** Asking a friend for a copy (feature 0072). Nothing stored: the rest of the transactions is not ported. */
    val transactions: TransactionRepository = TransactionRepository(api)
    val coverWall: CoverWallRepository = CoverWallRepository(publicApi, preferences)

    /** Publishing into inventaire.io's open database (feature 0020). Never optimistic. */
    val creation: EntityCreationRepository = EntityCreationRepository(api = api, publicApi = publicApi)

    /** « Ranger mes livres »: app-scoped, so a draft and a run in flight both outlive the screen. */
    val sortSession: SortSession = SortSession(
        scope = applicationScope,
        users = users,
        shelves = shelves,
        inventory = inventory,
        db = database,
        errorReporter = errorReporter,
    )

    val session: SessionCoordinator = SessionCoordinator(
        scope = applicationScope,
        auth = auth,
        users = users,
        groups = groups,
        shelves = shelves,
        inventory = inventory,
        lists = lists,
        sortSession = sortSession,
        syncStatus = syncStatus,
    )

    /** Coil over the session-less client: covers are public, and must not touch the session. */
    fun imageLoader(context: Context): ImageLoader = ImageLoader.Builder(context)
        .components { add(OkHttpNetworkFetcherFactory(callFactory = { publicClient })) }
        .build()

    private companion object {
        val USER_AGENT: String = "Ex-libris/${BuildConfig.VERSION_NAME} (Android)"
    }
}
