package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.entities.InventaireClient
import studio.lunabee.exlibris.backend.entities.RelayedResource
import studio.lunabee.exlibris.backend.plugins.ApiException

/**
 * inventaire.io's `GET /api/entities/by-uris`, read anonymously: for the books' snapshots, and for the type and the
 * redirects of what a list is given (#74). Anything but a `200` inventaire.io can be read from answers `502`.
 */
class InventaireEntitiesReader(
    private val inventaire: InventaireClient,
) {
    /** [uris], with each of [parameters]' values joined as inventaire.io's arrays are: `relatives`, `attributes`. */
    suspend fun read(
        uris: List<String>,
        parameters: Map<String, List<String>> = emptyMap(),
    ): InventaireEntities {
        // `|` encoded: inventaire.io takes either, a stricter server only this.
        val query: String =
            (mapOf("uris" to uris) + parameters).entries.joinToString("&") { (name, values) ->
                "$name=${values.joinToString(SEPARATOR)}"
            }
        return inventaire.get("/api/entities/by-uris?$query", emptyMap(), RelayedResource.DATA.timeout) { parse(it) }
    }

    private suspend fun parse(response: HttpResponse): InventaireEntities {
        if (response.status != HttpStatusCode.OK) {
            logger.warn("inventaire.io answered {} to by-uris", response.status.value)
            throw ApiException.badGateway()
        }
        // kotlinx's `SerializationException` and a body of the wrong shape are both `IllegalArgumentException`s.
        return try {
            InventaireEntities.parse(response.bodyAsText())
        } catch (error: IllegalArgumentException) {
            throw ApiException.badGateway(error)
        }
    }

    private companion object {
        const val SEPARATOR: String = "%7C"

        val logger: Logger = LoggerFactory.getLogger(InventaireEntitiesReader::class.java)
    }
}
