package studio.lunabee.exlibris.backend

import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationStopped
import io.ktor.server.routing.routing
import studio.lunabee.exlibris.backend.db.PostgresConfig
import studio.lunabee.exlibris.backend.health.healthRoutes
import studio.lunabee.exlibris.backend.plugins.installRequestLogging
import studio.lunabee.exlibris.backend.plugins.installSerialization
import studio.lunabee.exlibris.backend.plugins.installStatusPages

fun Application.module() {
    val container = AppContainer(PostgresConfig.from(environment.config))
    container.migrate()
    monitor.subscribe(ApplicationStopped) { container.close() }

    installSerialization()
    installRequestLogging()
    installStatusPages()

    routing {
        healthRoutes(container.healthService)
    }
}
