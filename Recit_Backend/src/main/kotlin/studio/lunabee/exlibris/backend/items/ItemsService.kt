package studio.lunabee.exlibris.backend.items

import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace
import java.time.Clock

/** The books: creating, reading, changing and deleting them, as inventaire.io's `controllers/items`. */
class ItemsService(
    private val repository: ItemsRepository,
    private val snapshots: SnapshotsService,
    private val visibility: VisibilityValidator,
    private val clock: Clock,
) {
    /**
     * `POST /api/items`. Everything is checked before inventaire.io is asked for the snapshot; `isbn:` URIs are
     * accepted, and stored as the edition inventaire.io answers them with.
     */
    suspend fun create(
        ownerId: String,
        body: JsonBody,
    ): CreatedItem {
        val entity: String = body.string("entity").also(::requireEntityUri)
        val transaction: TransactionMode =
            body.optionalString("transaction")?.let(::transactionMode)
                ?: TransactionMode.INVENTORYING
        val keys: List<String> = visibility.read(body.element("visibility"), ownerId)
        val shelves: List<String> = ownShelves(ownerId, body.optionalStringList("shelves").orEmpty())
        val item =
            ItemRecord(
                id = DocumentId.new(),
                version = 1,
                owner = ownerId,
                entity = snapshots.store(entity),
                transaction = transaction,
                visibility = keys,
                details = body.optionalString("details")?.ifEmpty { null },
                notes = body.optionalString("notes")?.ifEmpty { null },
                previousEntities = null,
                created = clock.millis(),
                updated = null,
                shelves = shelves,
            )
        if (!repository.insert(item)) throw ApiException.unauthorized()
        return CreatedItem(item.document(ownerId, snapshots.snapshots(listOf(item.entity))[item.entity], busy = null))
    }

    /**
     * `GET /api/items/by-ids`, public: a book the caller may not see is absent, as on inventaire.io; `busy` while an
     * Échange holds it (#75).
     */
    suspend fun byIds(
        ids: List<String>,
        limit: Int?,
        offset: Int?,
        viewerId: String?,
    ): ItemsPage {
        val visible: List<ItemRecord> = repository.visible(ids, viewerId)
        val start: Int = offset ?: 0
        val page: List<ItemRecord> = visible.drop(start).let { if (limit == null) it else it.take(limit) }
        val byUri: Map<String, ItemSnapshot> = snapshots.snapshots(page.map { it.entity })
        val busy: Set<String> = repository.busy(page.map { it.id })
        return ItemsPage(
            items = page.map { it.document(viewerId, byUri[it.entity], busy = it.id in busy) },
            total = visible.size,
            offset = start,
        )
    }

    /**
     * `PUT /api/items/bulk-update`: one of inventaire.io's updatable attributes on every book of `ids`, all the
     * caller's. The books' snapshots are read again afterwards (decision 2).
     */
    suspend fun bulkUpdate(
        ownerId: String,
        body: JsonBody,
    ) {
        val items: List<ItemRecord> = repository.find(body.ids("ids"))
        val attribute: String = body.string("attribute")
        val value: JsonElement =
            body.element("value") ?: throw ApiException.missingParameter(ParameterPlace.BODY, "value")
        if (items.any { it.owner != ownerId }) {
            throw ApiException(HttpStatusCode.BadRequest, "user is not item owner")
        }
        val change: ItemChange = change(ownerId, attribute, value)
        if (items.isEmpty()) return
        repository.update(items.map { it.id }, change, clock.millis())
        snapshots.refreshTouched(items.map { it.entity })
    }

    /**
     * `POST /api/items/delete`: the books go, off every étagère; an unknown id is skipped, someone else's refused.
     * Answers the books deleted, as an étagère deleted `with-items` echoes them.
     */
    suspend fun delete(
        ownerId: String,
        ids: List<String>,
    ): List<ItemDocument> {
        val items: List<ItemRecord> = repository.find(ids)
        if (items.any { it.owner != ownerId }) throw ApiException(HttpStatusCode.Forbidden, "user isn't item owner")
        repository.delete(items.map { it.id })
        return items.map { it.document(ownerId, snapshot = null, busy = null) }
    }

    private suspend fun change(
        ownerId: String,
        attribute: String,
        value: JsonElement,
    ): ItemChange =
        when (attribute) {
            "transaction" -> ItemChange.Transaction(transactionMode(text(attribute, value)))
            "visibility" -> ItemChange.Visibility(visibility.read(value, ownerId))
            "details" -> ItemChange.Details(text(attribute, value))
            "notes" -> ItemChange.Notes(text(attribute, value))
            "shelves" -> ItemChange.Shelves(ownShelves(ownerId, shelfIds(value)))
            "entity" -> ItemChange.Entity(snapshots.store(text(attribute, value).also(::requireEntityUri)))
            in untouchedAttributes -> ItemChange.Untouched
            else -> throw ApiException(HttpStatusCode.BadRequest, "invalid attribute: $attribute")
        }

    /** Those of [shelfIds] that exist, all the owner's: inventaire.io's `validateShelves`. */
    private suspend fun ownShelves(
        ownerId: String,
        shelfIds: List<String>,
    ): List<String> {
        if (shelfIds.isEmpty()) return emptyList()
        shelfIds.firstOrNull { !DocumentId.isValid(it) }?.let { throw ApiException.invalidParameter("shelf", it) }
        val owners: Map<String, String> = repository.shelfOwners(shelfIds)
        if (owners.values.any { it != ownerId }) throw ApiException(HttpStatusCode.BadRequest, "invalid owner")
        return shelfIds.distinct().filter { it in owners }
    }

    private fun shelfIds(value: JsonElement): List<String> =
        (value as? JsonArray)?.map { text("shelves", it) }
            ?: throw ApiException.invalidParameter("shelves", value.toString())

    private fun text(
        attribute: String,
        value: JsonElement,
    ): String =
        (value as? JsonPrimitive)?.takeIf { it.isString }?.content
            ?: throw ApiException.invalidParameter(attribute, value.toString())

    private fun transactionMode(text: String): TransactionMode =
        TransactionMode.of(text) ?: throw ApiException.invalidParameter("transaction", text)

    private fun requireEntityUri(uri: String) {
        if (!entityUri.matches(uri)) throw ApiException.invalidParameter("entity", uri)
    }

    private companion object {
        /** inventaire.io's `ExtendedEntityUri`: the `isbn:` pseudo-URIs the scanner sends besides `wd:` and `inv:`. */
        val entityUri: Regex = Regex("""^(wd:Q\d+|inv:[0-9a-f]{32}|isbn:\w{10}(\w{3})?)$""")

        /** inventaire.io's `notUpdatable`, which `updateItemDoc` omits without a word. */
        val untouchedAttributes: Set<String> =
            setOf("_id", "_rev", "created", "updated", "owner", "history", "previousEntities")
    }
}
