package studio.lunabee.exlibris.backend

import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationStopped
import io.ktor.server.routing.routing
import studio.lunabee.exlibris.backend.auth.authRoutes
import studio.lunabee.exlibris.backend.health.healthRoutes
import studio.lunabee.exlibris.backend.plugins.installRateLimits
import studio.lunabee.exlibris.backend.plugins.installRequestLogging
import studio.lunabee.exlibris.backend.plugins.installSerialization
import studio.lunabee.exlibris.backend.plugins.installSessionCookies
import studio.lunabee.exlibris.backend.plugins.installStatusPages
import studio.lunabee.exlibris.backend.users.usersRoutes

fun Application.module() {
    val container = AppContainer(AppConfig.from(environment.config))
    container.migrate()
    monitor.subscribe(ApplicationStopped) { container.close() }

    installSerialization()
    installRequestLogging()
    installStatusPages()
    installSessionCookies(container.sessionCodec)
    installRateLimits()

    routing {
        healthRoutes(container.healthService)
        authRoutes(container.authService, container.accountLinkService)
        usersRoutes(container.usersService)
    }
}
