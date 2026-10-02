package studio.lunabee.nouveaurecit.data

import androidx.room.withTransaction
import kotlinx.coroutines.flow.Flow
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.IdsPayload
import studio.lunabee.nouveaurecit.network.dto.InventoryResultDto
import studio.lunabee.nouveaurecit.network.dto.ItemDto
import studio.lunabee.nouveaurecit.network.dto.ItemsDto
import studio.lunabee.nouveaurecit.network.dto.NewItemDto
import studio.lunabee.nouveaurecit.network.dto.OkMapDto
import studio.lunabee.nouveaurecit.network.dto.PostItemResponseDto
import studio.lunabee.nouveaurecit.network.dto.UpdateItemsDto

/** `InventoryModel`: my copies and my friends', synced work by work, edited optimistically. */
class InventoryRepository(
    private val api: ApiService,
    private val db: AppDatabase,
    private val entities: EntityRepository,
    private val runner: OptimisticRunner,
    private val syncStatus: SyncStatus,
) {
    private val dao = db.inventoryDao()

    fun observeItemsOf(ownerId: String): Flow<List<ItemRow>> = dao.observeItemsOf(ownerId)

    fun observeAll(): Flow<List<ItemRow>> = dao.observeAll()

    fun observeItem(id: String): Flow<ItemRow?> = dao.observeItem(id)

    fun observeItemsOfEdition(editionUri: String): Flow<List<ItemRow>> = dao.observeItemsOfEdition(editionUri)

    fun observeItemsOfWorks(workUris: List<String>): Flow<List<ItemRow>> = dao.observeItemsOfWorks(workUris)

    fun observeCountOf(ownerId: String): Flow<Int> = dao.observeCountOf(ownerId)

    /**
     * `/api/items/inventory-view`, then each author's works, then each work's items. Skipped when
     * nothing was added since the last sync. Every row is merged in place, never re-inserted.
     */
    suspend fun syncInventory(user: UserEntity) {
        val lastSync: Double? = user.lastInventorySync
        if (lastSync != null && user.lastItemAdded <= lastSync) return
        val isFirstSync: Boolean = lastSync == null
        if (isFirstSync) syncStatus.startFirstSync(user.id)
        try {
            val result: InventoryResultDto = api.get("/api/items/inventory-view", "user" to user.id)
            if (isFirstSync) syncStatus.announce(user.id, result.workUriItemsMap.values.sumOf { it.size })
            val synced: MutableSet<String> = mutableSetOf()
            for ((authorUri, workUris) in result.worksTree.author) {
                val works = runCatching { entities.fetchEntities(workUris) }.getOrNull() ?: continue
                val authorUris: List<String> = if (authorUri == UNKNOWN_AUTHOR) {
                    emptyList()
                } else {
                    runCatching { entities.getOrFetchAuthors(listOf(authorUri)) }.getOrNull()?.map { it.uri } ?: continue
                }
                works.forEach { entities.upsertWork(it, authorUris) }
                for (workUri in workUris) {
                    if (synced.add(workUri)) syncItems(workUri, result, user)
                }
            }
            for (workUri in result.workUriItemsMap.keys) {
                if (synced.add(workUri)) syncItems(workUri, result, user)
            }
            db.userDao().setLastInventorySync(user.id, System.currentTimeMillis().toDouble())
        } finally {
            if (isFirstSync) syncStatus.endFirstSync(user.id)
        }
    }

    private suspend fun syncItems(workUri: String, result: InventoryResultDto, owner: UserEntity) {
        val itemIds: List<String> = result.workUriItemsMap[workUri].orEmpty()
        if (itemIds.isEmpty()) return
        try {
            if (db.entityDao().work(workUri) == null) return
            val dtos: List<ItemDto> = itemIds.chunked(50).flatMap { batch ->
                api.get<ItemsDto>("/api/items/by-ids", "ids" to batch.joinToString("|")).items
            }
            db.withTransaction { dtos.forEach { upsertItem(it, owner.username, linkedWorkUri = workUri) } }
        } finally {
            syncStatus.receive(owner.id, itemIds.size)
        }
    }

    /** One item into the store: its edition (from the snapshot when the store has none), its row, its shelves. */
    private suspend fun upsertItem(dto: ItemDto, ownerUsername: String, linkedWorkUri: String?) {
        val entityDao = db.entityDao()
        if (entityDao.edition(dto.entity) == null) entityDao.upsertEditions(listOf(Merges.edition(dto.entity, dto.snapshot)))
        if (linkedWorkUri != null) entities.linkEdition(dto.entity, listOf(linkedWorkUri))
        dao.upsert(listOf(Merges.item(dao.get(dto.id), dto, ownerUsername)))
        val shelfIds: List<String> = db.shelfDao().existingIds(dto.shelves.orEmpty())
        db.shelfDao().replaceShelvesOfItem(dto.id, shelfIds)
    }

    /** `POST /api/items` — server-first, like every create (ADR 0001). */
    suspend fun postNewItem(
        entityUri: String,
        owner: UserEntity,
        transaction: TransactionType = TransactionType.Inventorying,
        visibility: List<Visibility> = listOf(Visibility.Friends, Visibility.Groups),
    ): String {
        val payload = NewItemDto(entity = entityUri, transaction = transaction.raw, visibility = visibility.map { it.raw })
        val response: PostItemResponseDto = api.send("/api/items", body = payload)
        db.withTransaction { upsertItem(response.item, owner.username, linkedWorkUri = null) }
        db.entityDao().workUris(entityUri).forEach { entities.linkEdition(response.item.entity, listOf(it)) }
        return response.item.id
    }

    /** `POST /api/items/delete` — server-first: the row goes only once the server said `ok`. */
    suspend fun removeItem(itemId: String) {
        val response: OkMapDto = api.send("/api/items/delete", body = IdsPayload(listOf(itemId)))
        if (!response.ok) throw NetworkError.BadResponse()
        dao.delete(itemId)
    }

    suspend fun updateTransaction(itemId: String, newValue: TransactionType) {
        val previous: TransactionType = dao.get(itemId)?.transaction ?: return
        runner.run(
            apply = { dao.setTransaction(itemId, newValue.raw) },
            revert = { dao.setTransaction(itemId, previous.raw) },
            request = { bulkUpdate(itemId, "transaction", newValue.raw) },
            stillThere = { dao.get(itemId) != null },
        )
    }

    suspend fun updateDetails(itemId: String, details: String) {
        val item: InventoryItemEntity = dao.get(itemId) ?: return
        if (item.details == details) return
        val previous: String = item.details
        runner.run(
            apply = { dao.setDetails(itemId, details) },
            revert = { if (dao.get(itemId)?.details == details) dao.setDetails(itemId, previous) },
            request = { bulkUpdate(itemId, "details", details) },
            stillThere = { dao.get(itemId) != null },
        )
    }

    private suspend fun bulkUpdate(itemId: String, attribute: String, value: String) {
        val response: OkMapDto = api.send("/api/items/bulk-update", method = "PUT", body = UpdateItemsDto(listOf(itemId), attribute, value))
        if (!response.ok) throw NetworkError.BadResponse()
    }

    private companion object {
        const val UNKNOWN_AUTHOR: String = "unknown"
    }
}
