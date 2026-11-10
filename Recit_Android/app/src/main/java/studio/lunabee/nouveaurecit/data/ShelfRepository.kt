package studio.lunabee.nouveaurecit.data

import androidx.room.withTransaction
import kotlinx.coroutines.flow.Flow
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.db.ShelfEntity
import studio.lunabee.nouveaurecit.data.db.ShelfItemCrossRef
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.data.shelves.ShelfMembership
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.IdsPayload
import studio.lunabee.nouveaurecit.network.dto.NewShelfDto
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
import studio.lunabee.nouveaurecit.network.dto.ShelfResponseDto
import studio.lunabee.nouveaurecit.network.dto.ShelvesResponseDto
import studio.lunabee.nouveaurecit.network.dto.ShelvesWithItemsResponseDto
import studio.lunabee.nouveaurecit.network.dto.UpdateShelfDto

/**
 * `ShelfModel`. Unlike the rest of the app, creating and deleting a shelf are optimistic too
 * (ADR 0001, amended; ADR 0004): the carousel is the app's identity.
 */
class ShelfRepository(
    private val api: ApiService,
    private val db: AppDatabase,
    private val runner: OptimisticRunner,
    private val membership: ShelfMembership,
) {
    private val dao = db.shelfDao()

    fun observeShelvesOf(ownerId: String): Flow<List<ShelfWithItems>> = dao.observeShelvesOf(ownerId)

    fun observeShelf(id: String): Flow<ShelfWithItems?> = dao.observeShelf(id)

    fun observeShelfIdsOf(itemId: String): Flow<List<String>> = dao.observeShelfIdsOf(itemId)

    /** `?action=by-owners`, upserted, the owner's missing shelves deleted; then membership from `?action=by-ids`. */
    suspend fun syncShelves(owner: UserEntity) {
        val response: ShelvesResponseDto = api.get("/api/shelves", "action" to "by-owners", "owners" to owner.id)
        val dtos = response.shelves.values.filter { it.owner == owner.id }
        db.withTransaction {
            val existing: Map<String, ShelfEntity> = dao.shelvesOf(owner.id).associateBy { it.id }
            dao.upsert(dtos.map { Merges.shelf(existing[it.id], it) })
            val gone: List<String> = existing.keys.filter { id -> dtos.none { it.id == id } && !OptimisticRunner.isOptimistic(id) }
            dao.delete(gone)
        }
        if (dtos.isEmpty()) return
        val withItems: ShelvesWithItemsResponseDto = api.get(
            "/api/shelves",
            "action" to "by-ids",
            "ids" to dtos.joinToString("|") { it.id },
            "with-items" to "true",
        )
        db.withTransaction {
            for (dto in dtos) {
                val itemIds: List<String> = withItems.shelves[dto.id]?.items.orEmpty()
                val known: Set<String> = db.inventoryDao().get(itemIds).map { it.id }.toSet()
                dao.replaceItems(dto.id, itemIds.filter { it in known })
            }
        }
    }

    /** Optimistic: a placeholder under an `optimistic:` id at once, swapped for the server's shelf. */
    suspend fun createShelf(owner: UserEntity, name: String, description: String, visibility: List<Visibility>, itemIds: List<String> = emptyList()) {
        val placeholder = ShelfEntity(
            id = OptimisticRunner.makeId(),
            name = name.trim(),
            description = description.trim(),
            ownerId = owner.id,
            visibility = visibility,
            created = System.currentTimeMillis().toDouble(),
        )
        runner.run(
            apply = {
                dao.upsert(listOf(placeholder))
                dao.link(itemIds.map { ShelfItemCrossRef(placeholder.id, it) })
            },
            revert = { dao.delete(listOf(placeholder.id)) },
            request = {
                val response: ShelfResponseDto = api.send(
                    "/api/shelves",
                    body = NewShelfDto(placeholder.name, placeholder.description.ifEmpty { null }, visibility.map { it.raw }),
                    query = listOf("action" to "create"),
                )
                db.withTransaction {
                    dao.delete(listOf(placeholder.id))
                    dao.upsert(listOf(Merges.shelf(null, response.shelf)))
                }
                if (itemIds.isNotEmpty()) membership.send(response.shelf.id, itemIds, add = true)
            },
            stillThere = { true },
        )
    }

    suspend fun updateShelf(shelfId: String, name: String, description: String, visibility: List<Visibility>) {
        val previous: ShelfEntity = dao.get(shelfId) ?: return
        val updated: ShelfEntity = previous.copy(name = name.trim(), description = description.trim(), visibility = visibility)
        runner.run(
            apply = { dao.upsert(listOf(updated)) },
            revert = { dao.upsert(listOf(previous)) },
            request = {
                val response: ShelfResponseDto = api.send(
                    "/api/shelves",
                    body = UpdateShelfDto(shelfId, updated.name, updated.description, visibility.map { it.raw }),
                    query = listOf("action" to "update"),
                )
                dao.upsert(listOf(Merges.shelf(dao.get(shelfId), response.shelf)))
            },
            stillThere = { dao.get(shelfId) != null },
        )
    }

    /** Optimistic delete: the shelf and its memberships are snapshotted first, and put back on failure. */
    suspend fun deleteShelf(shelfId: String) {
        val shelf: ShelfEntity = dao.get(shelfId) ?: return
        val itemIds: List<String> = dao.itemIds(shelfId)
        runner.run(
            apply = { dao.delete(listOf(shelfId)) },
            revert = {
                dao.upsert(listOf(shelf))
                val known: Set<String> = db.inventoryDao().get(itemIds).map { it.id }.toSet()
                dao.link(itemIds.filter { it in known }.map { ShelfItemCrossRef(shelfId, it) })
            },
            request = { api.send<IdsPayload, OkStatusDto>("/api/shelves", body = IdsPayload(listOf(shelfId)), query = listOf("action" to "delete")) },
        )
    }

    /** `ShelfModel.addItems`: one optimistic `add-items` with the books not on the étagère yet — see [ShelfMembership.add]. */
    suspend fun addItems(shelfId: String, itemIds: List<String>) {
        membership.add(shelfId, itemIds)
    }

    suspend fun removeItem(shelfId: String, itemId: String) {
        membership.remove(shelfId, itemId)
    }

    /**
     * `createShelfAwaitingServer`: `?action=create`, **awaited**, then the server's shelf upserted and
     * returned. For « Ranger mes livres », whose apply needs the real `_id` before it can file anything
     * and must know the creation landed before it ticks the étagère (iOS PRD 0008). Created private and
     * without a description, as the sorting surface asks only for a name.
     */
    suspend fun createShelfNow(name: String): ShelfEntity {
        val response: ShelfResponseDto = api.send(
            "/api/shelves",
            body = NewShelfDto(name.trim(), null, emptyList()),
            query = listOf("action" to "create"),
        )
        val shelf: ShelfEntity = Merges.shelf(dao.get(response.shelf.id), response.shelf)
        dao.upsert(listOf(shelf))
        return shelf
    }

    /**
     * `addItemsAwaitingServer`: one `add-items` call, awaited, local membership reconciled from the
     * answer. Items the shelf already holds are dropped from the payload, and an empty payload is a
     * no-op — which is what makes a sorting apply that stopped partway safe to resume.
     */
    suspend fun addItemsNow(shelfId: String, itemIds: List<String>) {
        membership.addNow(shelfId, itemIds)
    }

    /** `removeItemsAwaitingServer`: the mirror of [addItemsNow] — only items the shelf holds are sent. */
    suspend fun removeItemsNow(shelfId: String, itemIds: List<String>) {
        membership.removeNow(shelfId, itemIds)
    }

    fun observeCountOf(ownerId: String): Flow<Int> = dao.observeCountOf(ownerId)
}
