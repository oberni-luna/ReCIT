package studio.lunabee.exlibris.backend.search

import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import studio.lunabee.exlibris.backend.plugins.queryParameter

/** Public, as on inventaire.io: the welcome screen's readers are not signed in. */
fun Route.searchRoutes(service: SearchService) {
    get("/api/search") {
        val parameters = call.request.queryParameters
        call.respond(service.search(call.queryParameter("types"), parameters["search"], parameters["limit"]))
    }
}
