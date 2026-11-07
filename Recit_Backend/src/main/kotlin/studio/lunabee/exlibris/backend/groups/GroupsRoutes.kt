package studio.lunabee.exlibris.backend.groups

import io.ktor.http.HttpStatusCode
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.put
import io.ktor.server.routing.route
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.OkResponse
import studio.lunabee.exlibris.backend.plugins.queryParameter
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser
import studio.lunabee.exlibris.backend.plugins.sessionUserId

/** inventaire.io's `controllers/groups/groups.ts`: reads by `GET`, creation by `POST`, every change by `PUT`. */
fun Route.groupsRoutes(
    groups: GroupsService,
    memberships: GroupMembershipService,
) {
    route("/api/groups") {
        get {
            call.respond(groups.userGroups(call.requireSessionUser()))
        }
        get("by-id") {
            call.respond(groups.byId(call.queryParameter("id"), call.sessionUserId))
        }
        post {
            val userId: String = call.requireSessionUser()
            call.respond(HttpStatusCode.Created, groups.create(userId, call.receiveJsonBody()))
        }
        put("update-settings") {
            val userId: String = call.requireSessionUser()
            call.respond(groups.updateSettings(userId, call.receiveJsonBody()))
        }
        GroupMembershipAction.entries.forEach { action ->
            put(action.path) {
                val userId: String = call.requireSessionUser()
                val body: JsonBody = call.receiveJsonBody()
                val groupId: String = body.string("group")
                memberships.act(action, userId, groupId, if (action.targetsAnotherUser) body.string("user") else null)
                call.respond(OkResponse())
            }
        }
    }
}
