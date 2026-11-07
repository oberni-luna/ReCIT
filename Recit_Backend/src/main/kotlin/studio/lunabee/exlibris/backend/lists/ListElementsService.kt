package studio.lunabee.exlibris.backend.lists

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import java.time.Clock

/** `add-elements`, `remove-elements` and `update-element`: what a list holds, written by its creator alone. */
class ListElementsService(
    private val lists: ListsRepository,
    private val repository: ListElementsRepository,
    private val entities: ListEntitiesChecker,
    private val clock: Clock,
) {
    /**
     * Adds `uris` to the list `id`, each checked on inventaire.io and stored under its redirect's target, after the
     * last element. A URI the list already holds, sent or reached by a redirect, creates nothing and comes back in
     * `alreadyInList`, as inventaire.io answers it.
     */
    suspend fun add(
        creatorId: String,
        body: JsonBody,
    ): ElementsAddition {
        val list: ListRecord = owned(creatorId, ListRules.id(body))
        val uris: List<String> = ListRules.uris(body)
        val held: List<ListElementRecord> = repository.held(list.id, uris)
        val missing: List<String> = uris - held.map { it.uri }.toSet()
        val canonical: Map<String, String> =
            if (missing.isEmpty()) emptyMap() else entities.canonical(missing, list.type)
        val targets: List<String> = missing.map { canonical.getValue(it) }.distinct()
        val heldTargets: List<ListElementRecord> = repository.held(list.id, targets - missing.toSet())
        val created: List<ListElementRecord> =
            repository.add(list.id, targets - heldTargets.map { it.uri }.toSet(), clock.millis())
        return ElementsAddition(
            createdElements = created.map { it.document() },
            alreadyInList = (held + heldTargets).map { it.document() },
        )
    }

    /** Takes `uris` out of the list `id`; none of them in it answers inventaire.io's `404`. */
    suspend fun remove(
        creatorId: String,
        body: JsonBody,
    ): ListAnswer {
        val list: ListRecord = owned(creatorId, ListRules.id(body))
        val found: List<ListElementRecord> = repository.held(list.id, ListRules.uris(body))
        if (found.isEmpty()) throw ApiException(HttpStatusCode.NotFound, "not found")
        repository.delete(found.map { it.id })
        return ListAnswer(list.document())
    }

    /**
     * `update-element`: the `comment` sent (`""` or `null` clears it), and with `list` the element moved to the end of
     * another list of its creator's, checked as an addition to it would be. Changing nothing is refused.
     */
    suspend fun update(
        creatorId: String,
        body: JsonBody,
    ): ListElementDocument {
        val element: ListElementRecord =
            repository.find(ListRules.id(body)) ?: throw ApiException.missingDocument()
        val source: ListRecord = lists.find(listOf(element.listId)).single()
        val recipient: ListRecord? = body.optionalString("list")?.let { recipient(creatorId, element, source, body) }
        val comment: String? =
            if (body.element("comment") == null) element.comment else ListRules.comment(body.optionalString("comment"))
        val refusal: ApiException? =
            when {
                source.creator != creatorId -> ListsService.wrongUser()
                recipient == null && comment == element.comment -> ApiException(HttpStatusCode.BadRequest, NOTHING)
                else -> null
            }
        refusal?.let { throw it }
        return repository.update(element.id, comment, recipient?.id, clock.millis()).document()
    }

    /** inventaire.io's `validateUpdateListing`: both lists the creator's, the element welcome in the recipient. */
    private suspend fun recipient(
        creatorId: String,
        element: ListElementRecord,
        source: ListRecord,
        body: JsonBody,
    ): ListRecord {
        val recipient: ListRecord =
            lists.find(listOf(ListRules.id(body, "list"))).singleOrNull() ?: throw ApiException.missingDocument()
        if (source.creator != creatorId || recipient.creator != creatorId) throw ListsService.wrongUser()
        entities.canonical(listOf(element.uri), recipient.type)
        refuseMove(element, source, recipient)
        return recipient
    }

    /** The element moved within its own list, or into one that already holds its URI: inventaire.io's `400`s. */
    private suspend fun refuseMove(
        element: ListElementRecord,
        source: ListRecord,
        recipient: ListRecord,
    ) {
        val refusal: String? =
            when {
                recipient.id == source.id -> "element already belongs to the list"
                repository.held(recipient.id, listOf(element.uri)).isNotEmpty() -> "element is already in the list"
                else -> null
            }
        refusal?.let { throw ApiException(HttpStatusCode.BadRequest, it) }
    }

    /** The list [listId], [creatorId]'s, or inventaire.io's `404` and `403 wrong user`. */
    private suspend fun owned(
        creatorId: String,
        listId: String,
    ): ListRecord {
        val list: ListRecord = lists.find(listOf(listId)).singleOrNull() ?: throw ApiException.missingDocument()
        if (list.creator != creatorId) throw ListsService.wrongUser()
        return list
    }

    private companion object {
        const val NOTHING: String = "nothing to update"
    }
}
