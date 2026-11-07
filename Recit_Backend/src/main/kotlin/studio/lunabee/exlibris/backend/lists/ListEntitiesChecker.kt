package studio.lunabee.exlibris.backend.lists

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.items.InventaireEntities
import studio.lunabee.exlibris.backend.items.InventaireEntitiesReader
import studio.lunabee.exlibris.backend.items.text
import studio.lunabee.exlibris.backend.plugins.ApiException

/**
 * inventaire.io's `validateEntitiesCanBeAdded`, read from inventaire.io itself (decision 3): each URI must name an
 * entity of a type the list holds. inventaire.io silent or refusing answers `502`, and nothing is added.
 */
class ListEntitiesChecker(
    private val inventaire: InventaireEntitiesReader,
) {
    /**
     * [uris], each mapped to the URI inventaire.io files it under now — a redirect's target. An entity of another
     * type, then an unknown one, answers inventaire.io's `403`s.
     */
    suspend fun canonical(
        uris: List<String>,
        type: ListType,
    ): Map<String, String> {
        val entities: InventaireEntities = inventaire.read(uris, mapOf("attributes" to listOf("info")))
        val found: Map<String, String?> =
            uris.filter { entities.entity(it) != null }.associateWith { entities.entity(it)?.text("type") }
        if (found.values.any { it !in type.entityTypes }) {
            throw ApiException(HttpStatusCode.Forbidden, "cannot add this entity type to this list")
        }
        if (found.size < uris.size) throw ApiException(HttpStatusCode.Forbidden, "entities not found")
        return uris.associateWith { entities.canonical(it) }
    }
}
