package studio.lunabee.exlibris.backend.health

import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get

fun Route.healthRoutes(service: HealthService) {
    get("/health") {
        call.respond(service.check())
    }
}
