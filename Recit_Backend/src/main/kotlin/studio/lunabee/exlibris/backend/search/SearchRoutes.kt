package studio.lunabee.exlibris.backend.search

import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import studio.lunabee.exlibris.backend.entities.EntitiesService
import studio.lunabee.exlibris.backend.entities.RelayedResource
import studio.lunabee.exlibris.backend.entities.relay
import studio.lunabee.exlibris.backend.plugins.queryParameter

/**
 * Public, as on inventaire.io: the welcome screen's readers are not signed in. Entity types are inventaire.io's to
 * search: relayed through [entities].
 */
fun Route.searchRoutes(
    service: SearchService,
    entities: EntitiesService,
) {
    get("/api/search") {
        val parameters = call.request.queryParameters
        val types: String = call.queryParameter("types")
        if (service.isRelayed(types)) {
            call.relay(entities, RelayedResource.DATA)
        } else {
            call.respond(service.search(types, parameters["search"], parameters["limit"]))
        }
    }
}
