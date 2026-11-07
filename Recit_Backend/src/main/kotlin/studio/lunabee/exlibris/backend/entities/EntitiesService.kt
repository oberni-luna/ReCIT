package studio.lunabee.exlibris.backend.entities

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsChannel
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.contentLength
import io.ktor.http.contentType

/**
 * The bibliographic reads the backend does not own, relayed to inventaire.io unchanged (#76): the request without
 * the reader's session, the answer without inventaire.io's.
 */
class EntitiesService(
    private val inventaire: InventaireClient,
) {
    /**
     * Relays a `GET` of [pathAndQuery] and hands inventaire.io's answer to [respond]. Only [forwardedHeaders] leave
     * (decision 2): never `Cookie` nor `Authorization`. Only the status, the body, `Content-Type` and the
     * [resource]'s kept headers come back (decision 3): never `Set-Cookie`.
     */
    suspend fun relay(
        pathAndQuery: String,
        requestHeaders: Headers,
        resource: RelayedResource,
        respond: suspend (RelayedAnswer) -> Unit,
    ) {
        val forwarded: Map<String, String> =
            forwardedHeaders.mapNotNull { name -> requestHeaders[name]?.let { name to it } }.toMap()
        inventaire.get(pathAndQuery, forwarded, resource.timeout) { response ->
            respond(answer(response, resource))
        }
    }

    private suspend fun answer(
        response: HttpResponse,
        resource: RelayedResource,
    ): RelayedAnswer =
        RelayedAnswer(
            status = response.status,
            contentType = response.contentType(),
            contentLength = response.contentLength(),
            headers =
                Headers.build {
                    resource.keptHeaders.forEach { name -> response.headers[name]?.let { append(name, it) } }
                },
            body = response.bodyAsChannel(),
        )

    private companion object {
        val forwardedHeaders: List<String> =
            listOf(HttpHeaders.Accept, HttpHeaders.AcceptLanguage, HttpHeaders.IfNoneMatch)
    }
}
