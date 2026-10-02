package studio.lunabee.nouveaurecit.data

import androidx.room.withTransaction
import kotlinx.coroutines.flow.Flow
import studio.lunabee.nouveaurecit.data.db.AppDatabase
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.AddToListDto
import studio.lunabee.nouveaurecit.network.dto.AddToListResponseDto
import studio.lunabee.nouveaurecit.network.dto.DeleteListElementsDto
import studio.lunabee.nouveaurecit.network.dto.ListDto
import studio.lunabee.nouveaurecit.network.dto.ListElementDto
import studio.lunabee.nouveaurecit.network.dto.ListsDto
import studio.lunabee.nouveaurecit.network.dto.NewListDto
import studio.lunabee.nouveaurecit.network.dto.NewListResponseDto
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
import studio.lunabee.nouveaurecit.network.dto.RemoveElementsResponseDto
import studio.lunabee.nouveaurecit.network.dto.SingleIdsPayload
import studio.lunabee.nouveaurecit.network.dto.UpdateListElementDto

/** `ListModel`: book lists against the `/api/lists` endpoints. */
class ListRepository(
    private val api: ApiService,
    private val db: AppDatabase,
    private val runner: OptimisticRunner,
) {
    private val dao = db.listDao()

    fun observeLists(): Flow<List<ListWithElements>> = dao.observeLists()

    fun observeList(id: String): Flow<ListWithElements?> = dao.observeList(id)

    /** Upsert in place, missing lists deleted; each list's elements likewise. */
    suspend fun syncLists(user: UserEntity) {
        val response: ListsDto = api.get("/api/lists/by-creators", "users" to user.id, "with-elements" to "true")
        db.withTransaction {
            val existing: Map<String, EntityListEntity> = dao.all().associateBy { it.id }
            dao.upsert(response.lists.map { Merges.list(existing[it.id], it) })
            dao.delete(existing.keys.filter { id -> response.lists.none { it.id == id } })
            response.lists.forEach { mergeElements(it) }
        }
    }

    private suspend fun mergeElements(dto: ListDto) {
        val elements: List<ListElementDto> = dto.elements ?: return
        val type: EntityListType = EntityListType.from(dto.type)
        val local: List<EntityListItemEntity> = dao.elements(dto.id)
        dao.upsertElements(elements.map { Merges.listElement(it, dto.id, type) })
        val gone: List<String> = local.map { it.id }.filter { id -> elements.none { it.id == id } && !OptimisticRunner.isOptimistic(id) }
        dao.deleteElements(gone)
    }

    /** Server-first. Returns the new list's id. */
    suspend fun createList(name: String, description: String, type: EntityListType, visibility: List<Visibility>): String {
        val response: NewListResponseDto = api.send(
            "/api/lists",
            body = NewListDto(name = name.trim(), description = description.trim(), visibility = visibility.map { it.raw }, type = type.raw),
        )
        dao.upsert(listOf(Merges.list(null, response.list)))
        return response.list.id
    }

    suspend fun createListAndAddWork(name: String, description: String, workUri: String): String {
        val id: String = createList(name, description, EntityListType.Work, emptyList())
        addEntities(id, listOf(workUri))
        return id
    }

    suspend fun updateList(id: String, name: String, description: String, visibility: List<Visibility>) {
        api.send<NewListDto, NewListResponseDto>(
            "/api/lists",
            method = "PUT",
            body = NewListDto(id = id, name = name.trim(), description = description.trim(), visibility = visibility.map { it.raw }),
        )
        dao.get(id)?.let { dao.upsert(listOf(it.copy(name = name.trim(), explanation = description.trim(), visibility = visibility))) }
    }

    /** `POST /api/lists/delete` — note `ids` is a single string there, not an array. */
    suspend fun deleteList(id: String) {
        api.send<SingleIdsPayload, OkStatusDto>("/api/lists/delete", body = SingleIdsPayload(id))
        dao.delete(listOf(id))
    }

    /** Optimistic placeholders, replaced by the server's `createdElements`. */
    suspend fun addEntities(listId: String, uris: List<String>, comment: String? = null) {
        val list: EntityListEntity = dao.get(listId) ?: return
        val placeholders: List<EntityListItemEntity> = uris.map { uri ->
            EntityListItemEntity(
                id = OptimisticRunner.makeId(),
                listId = listId,
                uri = uri,
                comment = comment.orEmpty(),
                created = System.currentTimeMillis().toDouble(),
                entityType = list.type,
            )
        }
        runner.run(
            apply = { dao.upsertElements(placeholders) },
            revert = { dao.deleteElements(placeholders.map { it.id }) },
            request = {
                val response: AddToListResponseDto = api.send("/api/lists/add-elements", method = "PUT", body = AddToListDto(listId, uris))
                if (!response.ok) throw NetworkError.BadResponse()
                val created: List<ListElementDto> = response.createdElements.map { element ->
                    if (!comment.isNullOrEmpty()) runCatching { updateElement(element.id, comment) }
                    element.copy(comment = comment ?: element.comment)
                }
                db.withTransaction {
                    dao.deleteElements(placeholders.map { it.id })
                    dao.upsertElements(created.map { Merges.listElement(it, listId, list.type) })
                }
            },
            stillThere = { dao.get(listId) != null },
        )
    }

    /** Server-first; `uris` are entity uris, not element ids. */
    suspend fun removeEntities(listId: String, uris: List<String>) {
        val response: RemoveElementsResponseDto = api.send("/api/lists/remove-elements", method = "PUT", body = DeleteListElementsDto(listId, uris))
        if (response.list == null) throw NetworkError.BadResponse()
        dao.deleteElementsByUri(listId, uris)
    }

    suspend fun updateElement(elementId: String, comment: String) {
        api.send<UpdateListElementDto, OkStatusDto>("/api/lists/update-element", method = "PUT", body = UpdateListElementDto(elementId, comment))
    }
}
