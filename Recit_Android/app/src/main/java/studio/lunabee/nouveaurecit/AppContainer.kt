package studio.lunabee.nouveaurecit

import android.content.Context
import coil3.ImageLoader
import coil3.network.okhttp.OkHttpNetworkFetcherFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import okhttp3.OkHttpClient
import studio.lunabee.nouveaurecit.auth.AuthRepository
import studio.lunabee.nouveaurecit.auth.AuthService
import studio.lunabee.nouveaurecit.auth.KeystoreSessionVault
import studio.lunabee.nouveaurecit.auth.SessionCookieJar
import studio.lunabee.nouveaurecit.data.EntityRepository
import studio.lunabee.nouveaurecit.data.ErrorReporter
import studio.lunabee.nouveaurecit.data.InventoryRepository
import studio.lunabee.nouveaurecit.data.ListRepository
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.data.SearchRepository
import studio.lunabee.nouveaurecit.data.SessionCoordinator
import studio.lunabee.nouveaurecit.data.ShelfRepository
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.UserPreferences
import studio.lunabee.nouveaurecit.data.UserRepository
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.network.ApiService
import java.util.concurrent.TimeUnit

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

    private val baseClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
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
    val users: UserRepository = UserRepository(api, database, optimisticRunner)
    val inventory: InventoryRepository = InventoryRepository(api, database, entities, optimisticRunner, syncStatus)
    val shelves: ShelfRepository = ShelfRepository(api, database, optimisticRunner)
    val lists: ListRepository = ListRepository(api, database, optimisticRunner)
    val search: SearchRepository = SearchRepository(api)

    val session: SessionCoordinator = SessionCoordinator(
        scope = applicationScope,
        auth = auth,
        users = users,
        shelves = shelves,
        inventory = inventory,
        lists = lists,
        syncStatus = syncStatus,
    )

    /** Coil over the session-less client: covers are public, and must not touch the session. */
    fun imageLoader(context: Context): ImageLoader = ImageLoader.Builder(context)
        .components { add(OkHttpNetworkFetcherFactory(callFactory = { publicClient })) }
        .build()
}
