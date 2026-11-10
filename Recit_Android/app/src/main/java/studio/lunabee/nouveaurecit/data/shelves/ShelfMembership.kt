package studio.lunabee.nouveaurecit.data.shelves

import kotlinx.coroutines.Job
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.ShelfItemsDto
import studio.lunabee.nouveaurecit.network.dto.ShelvesWithItemsResponseDto

/**
 * `ShelfModel`'s membership writes (iOS features 0006 and 0089): books put on an étagère or taken off it,
 * through `POST /api/shelves?action=add-items|remove-items`. Every call sends only what would change, and
 * the étagère's books in the store become what the server answers it now holds.
 */
class ShelfMembership(
    private val api: ApiService,
    private val store: ShelfMembershipStore,
    private val runner: OptimisticRunner,
) {
    /**
     * `ShelfModel.addItems(_:to:)`: the books not on the étagère yet, in one optimistic `add-items` — on the
     * étagère at once, taken off again if the server refuses. Only the étagère is checked before the revert,
     * so a book deleted during the round trip does not keep the others on it. Null when nothing is new.
     */
    suspend fun add(shelfId: String, itemIds: List<String>): Job? {
        val held: Set<String> = store.itemIds(shelfId).toSet()
        val added: List<String> = itemIds.distinct().filter { it !in held }
        if (added.isEmpty()) return null
        return runner.run(
            apply = { store.link(shelfId, added) },
            revert = { store.unlink(shelfId, added) },
            request = { send(shelfId, added, add = true) },
            stillThere = { store.hasShelf(shelfId) },
        )
    }

    /** One book off the étagère, optimistic: back on it if the server refuses. */
    suspend fun remove(shelfId: String, itemId: String): Job = runner.run(
        apply = { store.unlink(shelfId, listOf(itemId)) },
        revert = { store.link(shelfId, listOf(itemId)) },
        request = { send(shelfId, listOf(itemId), add = false) },
        stillThere = { store.hasShelf(shelfId) && store.hasItem(itemId) },
    )

    /** `addItemsAwaitingServer`: awaited, the books already there dropped, nothing sent when none is left. */
    suspend fun addNow(shelfId: String, itemIds: List<String>) {
        val held: Set<String> = store.itemIds(shelfId).toSet()
        val toSend: List<String> = itemIds.distinct().filter { it !in held }
        if (toSend.isEmpty()) return
        send(shelfId, toSend, add = true)
    }

    /** `removeItemsAwaitingServer`: the mirror of [addNow] — only the books the étagère holds are sent. */
    suspend fun removeNow(shelfId: String, itemIds: List<String>) {
        val held: Set<String> = store.itemIds(shelfId).toSet()
        val toSend: List<String> = itemIds.distinct().filter { it in held }
        if (toSend.isEmpty()) return
        send(shelfId, toSend, add = false)
    }

    /** One membership call, and the étagère's books in the store replaced by what the server says it now holds. */
    suspend fun send(shelfId: String, itemIds: List<String>, add: Boolean) {
        val response: ShelvesWithItemsResponseDto = api.send(
            "/api/shelves",
            body = ShelfItemsDto(shelfId, itemIds),
            query = listOf("action" to if (add) "add-items" else "remove-items"),
        )
        store.replaceItems(shelfId, response.shelves[shelfId]?.items.orEmpty())
    }
}
