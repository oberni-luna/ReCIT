package studio.lunabee.exlibris.backend.items

import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.db.Visibility
import studio.lunabee.exlibris.backend.groups.GroupsService
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/** `GET /api/items/inventory-view`, public: a reader's, an étagère's or a group's books, as works and owners. */
class InventoryViewService(
    private val repository: InventoryViewRepository,
    private val groups: GroupsService,
) {
    /** One of [userId], [shelfId], [groupId], in inventaire.io's order of precedence. */
    suspend fun view(
        userId: String?,
        shelfId: String?,
        groupId: String?,
        withoutShelf: Boolean,
        viewerId: String?,
    ): InventoryView {
        val scope: InventoryScope =
            when {
                userId != null -> InventoryScope.Owner(requireId("user", userId), withoutShelf)
                shelfId != null -> InventoryScope.OnShelf(requireShelf(shelfId))
                groupId != null -> groupScope(groupId, viewerId)
                else -> throw ApiException.missingParameter(ParameterPlace.QUERY, "user or group or shelf")
            }
        val items: List<ViewItem> = repository.items(scope, viewerId)
        return InventoryViewBuilder.build(items, repository.works(items.map { it.entity }))
    }

    private suspend fun requireShelf(shelfId: String): String {
        requireId("shelf", shelfId)
        if (!repository.shelfExists(shelfId)) throw ApiException.missingDocument()
        return shelfId
    }

    private suspend fun groupScope(
        groupId: String,
        viewerId: String?,
    ): InventoryScope.Group {
        val memberIds: List<String> = groups.memberIds(groupId)
        val keys: List<String> =
            if (viewerId != null && viewerId in memberIds) {
                listOf(Visibility.PUBLIC, Visibility.GROUPS, Visibility.GROUP_PREFIX + groupId)
            } else {
                listOf(Visibility.PUBLIC)
            }
        return InventoryScope.Group(memberIds, keys)
    }

    private fun requireId(
        name: String,
        id: String,
    ): String = id.takeIf(DocumentId::isValid) ?: throw ApiException.invalidParameter(name, id)
}
