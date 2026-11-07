package studio.lunabee.exlibris.backend.lists

import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.acceptLanguageItems
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.post
import io.ktor.server.routing.put
import studio.lunabee.exlibris.backend.plugins.action
import studio.lunabee.exlibris.backend.plugins.queryCount
import studio.lunabee.exlibris.backend.plugins.queryFlag
import studio.lunabee.exlibris.backend.plugins.queryIds
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser
import studio.lunabee.exlibris.backend.plugins.sessionUserId

private const val LISTS: String = "/api/lists"

/**
 * inventaire.io's `controllers/listings/listings.ts`, for the seven calls the apps make: each action at its path and
 * in the deprecated `?action=` form, with the legacy `POST` inventaire.io keeps for `create` and the element writes.
 */
fun Route.listsRoutes(
    lists: ListsService,
    elements: ListElementsService,
) {
    action(LISTS, "by-creators", listOf(HttpMethod.Get)) {
        val query = call.request.queryParameters
        val request =
            ListsPageRequest(
                limit = (call.queryCount("limit") ?: ListsPageRequest.DEFAULT_LIMIT).coerceAtLeast(1),
                offset = call.queryCount("offset") ?: 0,
                context = query["context"],
                withElements = call.queryFlag("with-elements"),
                attributes = ListRules.attributes(query["attributes"]),
                lang =
                    call.request
                        .acceptLanguageItems()
                        .firstOrNull()
                        ?.value
                        ?.substringBefore('-')
                        ?: ListsPageRequest.DEFAULT_LANG,
            )
        call.respond(lists.byCreators(call.queryIds("users"), request, call.sessionUserId))
    }
    post(LISTS) {
        val creatorId: String = call.requireSessionUser()
        call.respond(HttpStatusCode.Created, lists.create(creatorId, call.receiveJsonBody()))
    }
    action(LISTS, "create", listOf(HttpMethod.Post)) {
        val creatorId: String = call.requireSessionUser()
        call.respond(HttpStatusCode.Created, lists.create(creatorId, call.receiveJsonBody()))
    }
    put(LISTS) {
        val creatorId: String = call.requireSessionUser()
        call.respond(lists.update(creatorId, call.receiveJsonBody()))
    }
    action(LISTS, "delete", listOf(HttpMethod.Post)) {
        val creatorId: String = call.requireSessionUser()
        call.respond(lists.delete(creatorId, call.receiveJsonBody().ids("ids")))
    }
    val writes: List<HttpMethod> = listOf(HttpMethod.Put, HttpMethod.Post)
    action(LISTS, "add-elements", writes) {
        val creatorId: String = call.requireSessionUser()
        call.respond(elements.add(creatorId, call.receiveJsonBody()))
    }
    action(LISTS, "remove-elements", writes) {
        val creatorId: String = call.requireSessionUser()
        call.respond(elements.remove(creatorId, call.receiveJsonBody()))
    }
    action(LISTS, "update-element", writes) {
        val creatorId: String = call.requireSessionUser()
        call.respond(elements.update(creatorId, call.receiveJsonBody()))
    }
}
