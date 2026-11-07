package studio.lunabee.exlibris.backend.shelves

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.items.ItemDocument
import studio.lunabee.exlibris.backend.items.ItemsService
import studio.lunabee.exlibris.backend.items.VisibilityValidator
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import java.time.Clock

/** The étagères themselves, as inventaire.io's `controllers/shelves`; filing books on them is [ShelfItemsService]'s. */
class ShelvesService(
    private val repository: ShelvesRepository,
    private val shelfItems: ShelfItemsService,
    private val items: ItemsService,
    private val visibility: VisibilityValidator,
    private val clock: Clock,
) {
    /** `create`: the étagère, with `items` already filed on it when sent. */
    suspend fun create(
        ownerId: String,
        body: JsonBody,
    ): ShelfAnswer {
        val shelf =
            ShelfRecord(
                id = DocumentId.new(),
                version = 1,
                owner = ownerId,
                name = ShelfRules.name(body.optionalString("name")),
                description = ShelfRules.description(body.optionalString("description")),
                visibility = visibility.read(body.element("visibility"), ownerId),
                color = body.optionalString("color")?.let(ShelfRules::color),
                created = clock.millis(),
                updated = null,
            )
        if (!repository.insert(shelf)) throw ApiException.unauthorized()
        body.element("items")?.let { shelfItems.file(ownerId, shelf.id, body.ids("items"), isAdding = true) }
        return ShelfAnswer(shelf.document(ownerId))
    }

    /**
     * `update`, by `id` or the legacy `shelf` the apps send: the attributes sent, others kept. Changing nothing is
     * refused, as inventaire.io refuses it.
     */
    suspend fun update(
        ownerId: String,
        body: JsonBody,
    ): ShelfAnswer {
        val shelf: ShelfRecord =
            owned(ownerId, listOf(ShelfRules.id(body))).singleOrNull() ?: throw ApiException.missingDocument()
        val fields =
            ShelfFields(
                name = if (body.element("name") == null) shelf.name else ShelfRules.name(body.optionalString("name")),
                description =
                    body.element("description")?.let { ShelfRules.description(body.optionalString("description")) }
                        ?: shelf.description,
                visibility = body.element("visibility")?.let { visibility.read(it, ownerId) } ?: shelf.visibility,
                color = body.optionalString("color")?.let(ShelfRules::color) ?: shelf.color,
            )
        if (fields == ShelfFields(shelf.name, shelf.description, shelf.visibility, shelf.color)) {
            throw ApiException(HttpStatusCode.BadRequest, "nothing to update")
        }
        val now: Long = clock.millis()
        repository.update(shelf.id, fields, now)
        return ShelfAnswer(
            shelf
                .copy(
                    version = shelf.version + 1,
                    name = fields.name,
                    description = fields.description,
                    visibility = fields.visibility,
                    color = fields.color,
                    updated = now,
                ).document(ownerId),
        )
    }

    /**
     * `by-ids`, public: `404` when none exists, `401` or `403` when the caller may see none; otherwise those they
     * may see, with `with-items` (or `with-items-ids`) the books on them they may see.
     */
    suspend fun byIds(
        ids: List<String>,
        withItems: Boolean,
        viewerId: String?,
    ): ShelvesById {
        if (repository.find(ids).isEmpty()) throw ApiException(HttpStatusCode.NotFound, "not found")
        val visible: List<ShelfRecord> = repository.visible(ids, viewerId)
        if (visible.isEmpty()) {
            val status: HttpStatusCode = if (viewerId == null) HttpStatusCode.Unauthorized else HttpStatusCode.Forbidden
            throw ApiException(status, "unauthorized shelves access")
        }
        val itemIds: Map<String, List<String>>? = if (withItems) repository.itemIds(ids, viewerId) else null
        return ShelvesById(
            visible.associate { shelf ->
                shelf.id to shelf.document(viewerId, itemIds?.let { it[shelf.id].orEmpty() })
            },
        )
    }

    /** `by-owners`, public: the étagères of `owners` the caller may see. */
    suspend fun byOwners(
        owners: List<String>,
        viewerId: String?,
    ): ShelvesById = ShelvesById(repository.visibleOf(owners, viewerId).associate { it.id to it.document(viewerId) })

    /**
     * `delete`: the étagères go and their books stay, off them (decision 9); with `with-items` the books go too.
     * The answer echoes the étagères with their books' ids, and the books deleted.
     */
    suspend fun delete(
        ownerId: String,
        ids: List<String>,
        withItems: Boolean,
    ): ShelvesDeletion {
        val shelves: List<ShelfRecord> = owned(ownerId, ids)
        val itemIds: Map<String, List<String>> = repository.itemIds(shelves.map { it.id }, ownerId)
        val deleted: List<ItemDocument>? =
            if (withItems) items.delete(ownerId, itemIds.values.flatten().distinct()) else null
        repository.delete(shelves.map { it.id })
        return ShelvesDeletion(
            shelves = shelves.map { it.document(ownerId, itemIds[it.id].orEmpty()) },
            items = deleted,
        )
    }

    /** Those of [ids] that exist, all [ownerId]'s, or inventaire.io's `403 wrong owner`. */
    private suspend fun owned(
        ownerId: String,
        ids: List<String>,
    ): List<ShelfRecord> {
        val shelves: List<ShelfRecord> = repository.find(ShelfRules.ids(ids))
        if (shelves.any { it.owner != ownerId }) throw ApiException(HttpStatusCode.Forbidden, "wrong owner")
        return shelves
    }
}
