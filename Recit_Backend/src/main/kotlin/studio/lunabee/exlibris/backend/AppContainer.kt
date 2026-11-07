package studio.lunabee.exlibris.backend

import com.zaxxer.hikari.HikariDataSource
import org.jetbrains.exposed.v1.core.DatabaseConfig
import org.jetbrains.exposed.v1.jdbc.Database
import studio.lunabee.exlibris.backend.auth.AccountLinkService
import studio.lunabee.exlibris.backend.auth.AccountMails
import studio.lunabee.exlibris.backend.auth.AttemptLimiter
import studio.lunabee.exlibris.backend.auth.AuthRepository
import studio.lunabee.exlibris.backend.auth.AuthService
import studio.lunabee.exlibris.backend.auth.PasswordHasher
import studio.lunabee.exlibris.backend.auth.SessionCodec
import studio.lunabee.exlibris.backend.db.Postgres
import studio.lunabee.exlibris.backend.health.HealthRepository
import studio.lunabee.exlibris.backend.health.HealthService
import studio.lunabee.exlibris.backend.images.ImagesRepository
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.images.LocalImageStore
import studio.lunabee.exlibris.backend.mail.MailSender
import studio.lunabee.exlibris.backend.relations.RelationsRepository
import studio.lunabee.exlibris.backend.relations.RelationsService
import studio.lunabee.exlibris.backend.search.SearchRepository
import studio.lunabee.exlibris.backend.search.SearchService
import studio.lunabee.exlibris.backend.users.UserUpdateService
import studio.lunabee.exlibris.backend.users.UsersRepository
import studio.lunabee.exlibris.backend.users.UsersService
import java.time.Clock
import java.time.Duration

/**
 * The composition root, as `Recit_Android`'s `AppContainer`: repositories, then services, built by hand
 * once per process and read by [module]. Nothing else constructs a repository or a service.
 */
class AppContainer(
    config: AppConfig,
) : AutoCloseable {
    private val dataSource: HikariDataSource = Postgres.dataSource(config.postgres)

    // One attempt per transaction: a database that is down must say so at once, not after retries.
    private val database: Database =
        Database.connect(
            datasource = dataSource,
            databaseConfig = DatabaseConfig { defaultMaxAttempts = 1 },
        )

    private val clock: Clock = Clock.systemUTC()

    private val authRepository: AuthRepository = AuthRepository(database)

    private val passwordHasher: PasswordHasher = PasswordHasher()

    val healthService: HealthService = HealthService(HealthRepository(database))

    val sessionCodec: SessionCodec = SessionCodec(config.session, clock)

    val accountLinkService: AccountLinkService =
        AccountLinkService(
            repository = authRepository,
            passwordHasher = passwordHasher,
            mails = AccountMails(MailSender(config.mail), config.publicBaseUrl),
            mailsByAddress = AttemptLimiter(limit = 3, window = Duration.ofHours(1), clock = clock),
            clock = clock,
        )

    val authService: AuthService =
        AuthService(
            repository = authRepository,
            passwordHasher = passwordHasher,
            links = accountLinkService,
            loginByIdentifier = AttemptLimiter(limit = 5, window = Duration.ofMinutes(1), clock = clock),
            clock = clock,
        )

    private val usersRepository: UsersRepository = UsersRepository(database)

    val imagesService: ImagesService =
        ImagesService(
            store = LocalImageStore(config.images.directory),
            repository = ImagesRepository(database),
        )

    val relationsService: RelationsService = RelationsService(RelationsRepository(database), clock)

    val usersService: UsersService =
        UsersService(
            repository = usersRepository,
            relations = relationsService,
            images = imagesService,
        )

    val userUpdateService: UserUpdateService =
        UserUpdateService(
            repository = usersRepository,
            links = accountLinkService,
            images = imagesService,
            addressChanges = AttemptLimiter(limit = 3, window = Duration.ofHours(1), clock = clock),
        )

    val searchService: SearchService = SearchService(SearchRepository(database))

    fun migrate() {
        Postgres.migrate(dataSource)
    }

    override fun close() {
        dataSource.close()
    }
}
