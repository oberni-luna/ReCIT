package studio.lunabee.exlibris.backend.items

import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.post
import studio.lunabee.exlibris.backend.plugins.OkResponse
import studio.lunabee.exlibris.backend.plugins.action
import studio.lunabee.exlibris.backend.plugins.queryCount
import studio.lunabee.exlibris.backend.plugins.queryFlag
import studio.lunabee.exlibris.backend.plugins.queryIds
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser
import studio.lunabee.exlibris.backend.plugins.sessionUserId

private const val ITEMS: String = "/api/items"

/**
 * inventaire.io's `controllers/items/items.ts`, for the calls the apps make, at each action's path and in its
 * deprecated `?action=` form, with inventaire.io's legacy names (`bulk-update`, `delete-by-ids`). `by-entities` and
 * `recent-public` stay relayed to inventaire.io (#76).
 */
fun Route.itemsRoutes(
    items: ItemsService,
    views: InventoryViewService,
) {
    post(ITEMS) {
        val ownerId: String = call.requireSessionUser()
        call.respond(HttpStatusCode.Created, items.create(ownerId, call.receiveJsonBody()))
    }
    action(ITEMS, "by-ids", listOf(HttpMethod.Get)) {
        call.respond(
            items.byIds(call.queryIds("ids"), call.queryCount("limit"), call.queryCount("offset"), call.sessionUserId),
        )
    }
    action(ITEMS, "inventory-view", listOf(HttpMethod.Get)) {
        val query = call.request.queryParameters
        call.respond(
            views.view(
                userId = query["user"],
                shelfId = query["shelf"],
                groupId = query["group"],
                withoutShelf = call.queryFlag("without-shelf"),
                viewerId = call.sessionUserId,
            ),
        )
    }
    listOf("bulk", "bulk-update").forEach { name ->
        action(ITEMS, name, listOf(HttpMethod.Put)) {
            val ownerId: String = call.requireSessionUser()
            items.bulkUpdate(ownerId, call.receiveJsonBody())
            call.respond(OkResponse())
        }
    }
    listOf("delete", "delete-by-ids").forEach { name ->
        action(ITEMS, name, listOf(HttpMethod.Post)) {
            val ownerId: String = call.requireSessionUser()
            items.delete(ownerId, call.receiveJsonBody().ids("ids"))
            call.respond(OkResponse())
        }
    }
}
