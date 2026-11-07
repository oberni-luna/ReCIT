package studio.lunabee.exlibris.backend.shelves

import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.post
import io.ktor.server.routing.put
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.action
import studio.lunabee.exlibris.backend.plugins.queryFlag
import studio.lunabee.exlibris.backend.plugins.queryIds
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser
import studio.lunabee.exlibris.backend.plugins.sessionUserId

private const val SHELVES: String = "/api/shelves"

/**
 * inventaire.io's `controllers/shelves/shelves.ts`: each action at its path and in the `?action=` form the apps send,
 * and by `POST` as well as `PUT` where inventaire.io keeps the legacy `POST` (`update`, `add-items`, `remove-items`).
 */
fun Route.shelvesRoutes(
    shelves: ShelvesService,
    shelfItems: ShelfItemsService,
) {
    val writes: List<HttpMethod> = listOf(HttpMethod.Post, HttpMethod.Put)
    action(SHELVES, "by-ids", listOf(HttpMethod.Get)) {
        val withItems: Boolean = call.queryFlag("with-items") || call.queryFlag("with-items-ids")
        call.respond(shelves.byIds(call.queryIds("ids"), withItems, call.sessionUserId))
    }
    action(SHELVES, "by-owners", listOf(HttpMethod.Get)) {
        call.respond(shelves.byOwners(call.queryIds("owners"), call.sessionUserId))
    }
    post(SHELVES) {
        val ownerId: String = call.requireSessionUser()
        call.respond(HttpStatusCode.Created, shelves.create(ownerId, call.receiveJsonBody()))
    }
    action(SHELVES, "create", listOf(HttpMethod.Post)) {
        val ownerId: String = call.requireSessionUser()
        call.respond(HttpStatusCode.Created, shelves.create(ownerId, call.receiveJsonBody()))
    }
    put(SHELVES) {
        val ownerId: String = call.requireSessionUser()
        call.respond(shelves.update(ownerId, call.receiveJsonBody()))
    }
    action(SHELVES, "update", writes) {
        val ownerId: String = call.requireSessionUser()
        call.respond(shelves.update(ownerId, call.receiveJsonBody()))
    }
    action(SHELVES, "delete", listOf(HttpMethod.Post)) {
        val ownerId: String = call.requireSessionUser()
        val body: JsonBody = call.receiveJsonBody()
        call.respond(shelves.delete(ownerId, body.ids("ids"), body.flag("with-items")))
    }
    mapOf("add-items" to true, "remove-items" to false).forEach { (name, isAdding) ->
        action(SHELVES, name, writes) {
            val ownerId: String = call.requireSessionUser()
            val body: JsonBody = call.receiveJsonBody()
            call.respond(shelfItems.file(ownerId, body.string("id"), body.ids("items"), isAdding))
        }
    }
}
