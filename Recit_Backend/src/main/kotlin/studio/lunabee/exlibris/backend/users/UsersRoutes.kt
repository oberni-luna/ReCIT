package studio.lunabee.exlibris.backend.users

import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import studio.lunabee.exlibris.backend.plugins.requireSessionUser

fun Route.usersRoutes(service: UsersService) {
    get("/api/user") {
        call.respond(service.ownerDocument(call.requireSessionUser()))
    }
}
