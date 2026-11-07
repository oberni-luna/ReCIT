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
import studio.lunabee.exlibris.backend.entities.EntitiesService
import studio.lunabee.exlibris.backend.entities.InventaireClient
import studio.lunabee.exlibris.backend.groups.GroupMembershipService
import studio.lunabee.exlibris.backend.groups.GroupsRepository
import studio.lunabee.exlibris.backend.groups.GroupsService
import studio.lunabee.exlibris.backend.health.HealthRepository
import studio.lunabee.exlibris.backend.health.HealthService
import studio.lunabee.exlibris.backend.images.ImagesRepository
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.images.LocalImageStore
import studio.lunabee.exlibris.backend.items.InventoryViewRepository
import studio.lunabee.exlibris.backend.items.InventoryViewService
import studio.lunabee.exlibris.backend.items.ItemsRepository
import studio.lunabee.exlibris.backend.items.ItemsService
import studio.lunabee.exlibris.backend.items.SnapshotRefreshJob
import studio.lunabee.exlibris.backend.items.SnapshotsRepository
import studio.lunabee.exlibris.backend.items.SnapshotsService
import studio.lunabee.exlibris.backend.items.VisibilityValidator
import studio.lunabee.exlibris.backend.mail.MailSender
import studio.lunabee.exlibris.backend.relations.RelationsRepository
import studio.lunabee.exlibris.backend.relations.RelationsService
import studio.lunabee.exlibris.backend.search.SearchRepository
import studio.lunabee.exlibris.backend.search.SearchService
import studio.lunabee.exlibris.backend.shelves.ShelfItemsService
import studio.lunabee.exlibris.backend.shelves.ShelvesRepository
import studio.lunabee.exlibris.backend.shelves.ShelvesService
import studio.lunabee.exlibris.backend.users.UserDocumentsService
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

    private val userDocumentsService: UserDocumentsService = UserDocumentsService(usersRepository, relationsService)

    private val groupsRepository: GroupsRepository = GroupsRepository(database)

    val groupMembershipService: GroupMembershipService =
        GroupMembershipService(
            repository = groupsRepository,
            images = imagesService,
            clock = clock,
        )

    val groupsService: GroupsService =
        GroupsService(
            repository = groupsRepository,
            documents = userDocumentsService,
            images = imagesService,
            clock = clock,
        )

    val usersService: UsersService =
        UsersService(
            repository = usersRepository,
            documents = userDocumentsService,
            groups = groupMembershipService,
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

    private val inventaireClient: InventaireClient = InventaireClient(config.inventaire)

    val entitiesService: EntitiesService = EntitiesService(inventaireClient)

    val snapshotsService: SnapshotsService =
        SnapshotsService(
            inventaire = inventaireClient,
            repository = SnapshotsRepository(database),
            clock = clock,
        )

    val snapshotRefreshJob: SnapshotRefreshJob = SnapshotRefreshJob(snapshotsService)

    private val visibilityValidator: VisibilityValidator = VisibilityValidator(groupsService)

    val itemsService: ItemsService =
        ItemsService(
            repository = ItemsRepository(database),
            snapshots = snapshotsService,
            visibility = visibilityValidator,
            clock = clock,
        )

    val inventoryViewService: InventoryViewService =
        InventoryViewService(InventoryViewRepository(database), groupsService)

    private val shelvesRepository: ShelvesRepository = ShelvesRepository(database)

    val shelfItemsService: ShelfItemsService = ShelfItemsService(shelvesRepository, clock)

    val shelvesService: ShelvesService =
        ShelvesService(
            repository = shelvesRepository,
            shelfItems = shelfItemsService,
            items = itemsService,
            visibility = visibilityValidator,
            clock = clock,
        )

    fun migrate() {
        Postgres.migrate(dataSource)
    }

    override fun close() {
        inventaireClient.close()
        dataSource.close()
    }
}
