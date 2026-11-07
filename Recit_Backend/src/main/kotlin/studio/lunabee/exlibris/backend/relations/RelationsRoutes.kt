package studio.lunabee.exlibris.backend.relations

import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.route
import studio.lunabee.exlibris.backend.plugins.OkResponse
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser

fun Route.relationsRoutes(service: RelationsService) {
    route("/api/relations") {
        get {
            call.respond(service.relations(call.requireSessionUser()))
        }
        RelationAction.entries.forEach { action ->
            post(action.path) {
                val userId: String = call.requireSessionUser()
                service.act(action, userId, call.receiveJsonBody().string("user"))
                call.respond(OkResponse())
            }
        }
    }
}
