package studio.lunabee.exlibris.backend.users

import io.ktor.http.HttpMethod
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.delete
import io.ktor.server.routing.get
import io.ktor.server.routing.put
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.OkResponse
import studio.lunabee.exlibris.backend.plugins.action
import studio.lunabee.exlibris.backend.plugins.closeSession
import studio.lunabee.exlibris.backend.plugins.queryParameter
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser
import studio.lunabee.exlibris.backend.plugins.sessionUserId

fun Route.usersRoutes(
    users: UsersService,
    updates: UserUpdateService,
) {
    get("/api/user") {
        call.respond(users.ownerDocument(call.requireSessionUser()))
    }
    put("/api/user") {
        val userId: String = call.requireSessionUser()
        val body: JsonBody = call.receiveJsonBody()
        updates.update(userId, body.string("attribute"), body.element("value"))
        call.respond(OkResponse())
    }
    // inventaire.io logs the session out once the account is gone; its cookies would name no one.
    delete("/api/user") {
        users.deleteAccount(call.requireSessionUser())
        call.closeSession()
        call.respond(OkResponse())
    }
    action("/api/users", "by-ids", listOf(HttpMethod.Get)) {
        call.respond(users.byIds(call.queryParameter("ids"), call.sessionUserId))
    }
}
