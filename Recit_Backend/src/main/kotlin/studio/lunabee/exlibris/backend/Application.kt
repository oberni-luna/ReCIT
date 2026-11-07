package studio.lunabee.exlibris.backend

import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationStopped
import io.ktor.server.routing.routing
import studio.lunabee.exlibris.backend.auth.authRoutes
import studio.lunabee.exlibris.backend.entities.entitiesRoutes
import studio.lunabee.exlibris.backend.groups.groupsRoutes
import studio.lunabee.exlibris.backend.health.healthRoutes
import studio.lunabee.exlibris.backend.images.imagesRoutes
import studio.lunabee.exlibris.backend.items.itemsRoutes
import studio.lunabee.exlibris.backend.lists.listsRoutes
import studio.lunabee.exlibris.backend.plugins.installRateLimits
import studio.lunabee.exlibris.backend.plugins.installRequestLogging
import studio.lunabee.exlibris.backend.plugins.installSerialization
import studio.lunabee.exlibris.backend.plugins.installSessionCookies
import studio.lunabee.exlibris.backend.plugins.installStatusPages
import studio.lunabee.exlibris.backend.relations.relationsRoutes
import studio.lunabee.exlibris.backend.search.searchRoutes
import studio.lunabee.exlibris.backend.shelves.shelvesRoutes
import studio.lunabee.exlibris.backend.transactions.transactionsRoutes
import studio.lunabee.exlibris.backend.users.usersRoutes

fun Application.module() {
    val container = AppContainer(AppConfig.from(environment.config))
    container.migrate()
    monitor.subscribe(ApplicationStopped) { container.close() }
    container.snapshotRefreshJob.start(this)

    installSerialization()
    installRequestLogging()
    installStatusPages()
    installSessionCookies(container.sessionCodec)
    installRateLimits()

    routing {
        healthRoutes(container.healthService)
        authRoutes(container.authService, container.accountLinkService)
        usersRoutes(container.usersService, container.userUpdateService)
        relationsRoutes(container.relationsService)
        groupsRoutes(container.groupsService, container.groupMembershipService)
        searchRoutes(container.searchService, container.entitiesService)
        imagesRoutes(container.imagesService)
        entitiesRoutes(container.entitiesService)
        itemsRoutes(container.itemsService, container.inventoryViewService)
        shelvesRoutes(container.shelvesService, container.shelfItemsService)
        listsRoutes(container.listsService, container.listElementsService)
        transactionsRoutes(container.transactionsService, container.transactionMessagesService)
    }
}
