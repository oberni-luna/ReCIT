package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpMethod
import io.ktor.server.routing.Route
import io.ktor.server.routing.RoutingHandler
import io.ktor.server.routing.param
import io.ktor.server.routing.route

/**
 * Mounts [handler] where inventaire.io serves an action, for each of [methods]: `<path>/<name>`, and the deprecated
 * `<path>?action=<name>` the apps still send (`/api/shelves?action=add-items`).
 */
fun Route.action(
    path: String,
    name: String,
    methods: List<HttpMethod>,
    handler: RoutingHandler,
) {
    methods.forEach { method ->
        route("$path/$name", method) { handle(handler) }
        route(path, method) { param("action", name) { handle(handler) } }
    }
}
