package studio.lunabee.exlibris.backend.shelves

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.time.Clock

/** `add-items` and `remove-items`: the owner's books filed on, or taken off, one of their étagères. */
class ShelfItemsService(
    private val repository: ShelvesRepository,
    private val clock: Clock,
) {
    /**
     * Files [itemIds] on [shelfId] when [isAdding], takes them off otherwise, and answers the étagère with the ids
     * of every book on it. Someone else's étagère answers `403 wrong owner`, someone else's book `400 wrong owner`;
     * an unknown étagère changes nothing and answers none.
     */
    suspend fun file(
        ownerId: String,
        shelfId: String,
        itemIds: List<String>,
        isAdding: Boolean,
    ): ShelvesById {
        val shelf: ShelfRecord =
            repository.find(ShelfRules.ids(listOf(shelfId))).singleOrNull() ?: return ShelvesById(emptyMap())
        val owners: Map<String, String> = repository.itemOwners(itemIds)
        val refusal: ApiException? =
            when {
                shelf.owner != ownerId -> ApiException(HttpStatusCode.Forbidden, "wrong owner")
                owners.values.any { it != ownerId } -> ApiException(HttpStatusCode.BadRequest, "wrong owner")
                else -> null
            }
        refusal?.let { throw it }
        repository.file(shelf.id, itemIds.filter { it in owners }, isAdding, clock.millis())
        val onShelf: List<String> = repository.itemIds(listOf(shelf.id), ownerId)[shelf.id].orEmpty()
        return ShelvesById(mapOf(shelf.id to shelf.document(ownerId, onShelf)))
    }
}
