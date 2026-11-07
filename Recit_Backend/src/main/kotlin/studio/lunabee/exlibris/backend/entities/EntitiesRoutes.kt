package studio.lunabee.exlibris.backend.entities

import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.OutgoingContent
import io.ktor.server.application.ApplicationCall
import io.ktor.server.request.uri
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.route
import io.ktor.utils.io.ByteReadChannel
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.markRelayed

/** Every read under these is relayed, those the apps do not call yet included (#76 decision 1). */
private val relayedPrefixes: Map<String, RelayedResource> =
    mapOf(
        "/api/entities" to RelayedResource.DATA,
        "/api/data" to RelayedResource.DATA,
        "/api/tasks" to RelayedResource.DATA,
        "/img/entities" to RelayedResource.IMAGE,
        "/img/remote" to RelayedResource.IMAGE,
    )

/** The two `items` reads that need no session: feature 0051's copy count and the welcome wall of covers. */
private val relayedItemsPaths: List<String> = listOf("/api/items/by-entities", "/api/items/recent-public")

/**
 * Public, as on inventaire.io. Any other method under a relayed prefix is a bibliographic write, which answers `501`
 * until #77 signs them (#76 decision 6).
 */
fun Route.entitiesRoutes(service: EntitiesService) {
    relayedPrefixes.forEach { (prefix, resource) ->
        route("$prefix/{...}") {
            get { call.relay(service, resource) }
            handle {
                call.markRelayed()
                throw ApiException.notImplemented()
            }
        }
    }
    relayedItemsPaths.forEach { path ->
        get(path) { call.relay(service, RelayedResource.DATA) }
    }
}

/** Answers this `GET` with inventaire.io's answer to the same path and query string. */
suspend fun ApplicationCall.relay(
    service: EntitiesService,
    resource: RelayedResource,
) {
    markRelayed()
    service.relay(request.uri, request.headers, resource) { answer -> respond(answer.outgoingContent()) }
}

/** A `304` leaves without a body, as HTTP wants it: a streamed one would be sent chunked. */
private fun RelayedAnswer.outgoingContent(): OutgoingContent {
    val answer: RelayedAnswer = this
    return if (status == HttpStatusCode.NotModified) {
        object : OutgoingContent.NoContent() {
            override val status: HttpStatusCode = answer.status
            override val headers: Headers = answer.headers
        }
    } else {
        object : OutgoingContent.ReadChannelContent() {
            override val status: HttpStatusCode = answer.status
            override val contentType: ContentType? = answer.contentType
            override val contentLength: Long? = answer.contentLength
            override val headers: Headers = answer.headers

            override fun readFrom(): ByteReadChannel = answer.body
        }
    }
}
