package studio.lunabee.exlibris.backend.lists

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.db.Visibility
import studio.lunabee.exlibris.backend.items.VisibilityValidator
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace
import java.time.Clock

/** The lists themselves, as inventaire.io's `controllers/listings`; their elements are [ListElementsService]'s. */
class ListsService(
    private val repository: ListsRepository,
    private val elements: ListElementsRepository,
    private val visibility: VisibilityValidator,
    private val images: ListImagesSampler,
    private val clock: Clock,
) {
    /**
     * `by-creators`, public: [creators]' lists the caller may see, the newest first, one page of them; in a group's
     * `context` only those it may show (`public`, `groups` or that group). `total` counts them all.
     */
    suspend fun byCreators(
        creators: List<String>,
        request: ListsPageRequest,
        viewerId: String?,
    ): ListsPage {
        val context: String? = ListRules.context(request.context, visibility::isKey)
        val visible: List<ListRecord> =
            repository.visibleOf(creators, viewerId).filter { context == null || it.fits(context) }
        val page: List<ListRecord> = visible.drop(request.offset).take(request.limit)
        val pageIds: List<String> = page.map { it.id }
        val needsElements: Boolean = request.withElements || "images" in request.attributes
        val held: Map<String, List<ListElementRecord>> =
            if (needsElements && pageIds.isNotEmpty()) elements.ofLists(pageIds).groupBy { it.listId } else emptyMap()
        val counts: Map<String, Int>? = if ("total" in request.attributes) elements.counts(pageIds) else null
        val samples: Map<String, List<String>>? =
            if ("images" in request.attributes) images.samples(held, request.lang) else null
        val last: Int = request.offset + request.limit
        return ListsPage(
            lists =
                page.map { list ->
                    list.document(
                        elements = if (request.withElements) held[list.id].orEmpty().map { it.document() } else null,
                        totalElements = counts?.let { it[list.id] ?: 0 },
                        imagesSample = samples?.let { it[list.id].orEmpty() },
                    )
                },
            total = visible.size,
            next = last.takeIf { it < visible.size },
        )
    }

    /** `create`, `201`: a list of works unless another `type` is sent, seen by its creator alone unless shared. */
    suspend fun create(
        creatorId: String,
        body: JsonBody,
    ): ListAnswer {
        val name: String =
            body.optionalString("name") ?: throw ApiException.missingParameter(ParameterPlace.BODY, "name")
        val list =
            ListRecord(
                id = DocumentId.new(),
                version = 1,
                creator = creatorId,
                name = ListRules.name(name),
                description = ListRules.description(body.optionalString("description")),
                visibility = visibility.read(body.element("visibility"), creatorId),
                type = ListRules.type(body.optionalString("type")),
                created = clock.millis(),
                updated = null,
            )
        if (!repository.insert(list)) throw ApiException.unauthorized()
        return ListAnswer(list.document())
    }

    /**
     * `update`: the name, description and visibility sent, the others kept. An empty description or visibility
     * clears it; changing nothing is refused, as inventaire.io refuses it.
     */
    suspend fun update(
        creatorId: String,
        body: JsonBody,
    ): ListAnswer {
        val listId: String = ListRules.id(body)
        val sentVisibility: List<String>? = body.element("visibility")?.let { visibility.read(it, creatorId) }
        val list: ListRecord = owned(creatorId, listOf(listId)).singleOrNull() ?: throw ApiException.missingDocument()
        val fields =
            ListFields(
                name = if (body.element("name") == null) list.name else ListRules.name(body.optionalString("name")),
                description =
                    if (body.element("description") == null) {
                        list.description
                    } else {
                        ListRules.description(body.optionalString("description"))
                    },
                visibility = sentVisibility ?: list.visibility,
            )
        if (fields == list.fields) throw ApiException(HttpStatusCode.BadRequest, "nothing to update")
        val now: Long = clock.millis()
        repository.update(list.id, fields, now)
        return ListAnswer(
            list
                .copy(
                    version = list.version + 1,
                    name = fields.name,
                    description = fields.description,
                    visibility = fields.visibility,
                    updated = now,
                ).document(),
        )
    }

    /** `delete`: the lists go with their elements, both echoed. An id no list has is passed over. */
    suspend fun delete(
        creatorId: String,
        ids: List<String>,
    ): ListsDeletion {
        val lists: List<ListRecord> = owned(creatorId, ids)
        val listIds: List<String> = lists.map { it.id }
        val deleted: List<ListElementRecord> = if (listIds.isEmpty()) emptyList() else elements.ofLists(listIds)
        if (listIds.isNotEmpty()) repository.delete(listIds)
        return ListsDeletion(lists = lists.map { it.document() }, elements = deleted.map { it.document() })
    }

    /** Those of [ids] that exist, all [creatorId]'s, or inventaire.io's `403 wrong user`. */
    private suspend fun owned(
        creatorId: String,
        ids: List<String>,
    ): List<ListRecord> {
        val lists: List<ListRecord> = repository.find(ids)
        if (lists.any { it.creator != creatorId }) throw wrongUser()
        return lists
    }

    /** inventaire.io's `canBeDisplayedInContext`: a group's context shows what is public, or shared with groups. */
    private fun ListRecord.fits(context: String): Boolean =
        !context.startsWith(Visibility.GROUP_PREFIX) ||
            visibility.any { it == Visibility.PUBLIC || it == Visibility.GROUPS || it == context }

    companion object {
        /** inventaire.io's `validateListingOwnership`. */
        fun wrongUser(): ApiException = ApiException(HttpStatusCode.Forbidden, "wrong user")
    }
}
