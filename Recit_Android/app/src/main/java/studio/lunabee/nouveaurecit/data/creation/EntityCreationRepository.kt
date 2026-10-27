package studio.lunabee.nouveaurecit.data.creation

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import studio.lunabee.nouveaurecit.data.model.EntityLabel
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.CreatedEntityDto
import studio.lunabee.nouveaurecit.network.dto.EditableEditionsDto
import studio.lunabee.nouveaurecit.network.dto.EntityCreationRequest
import studio.lunabee.nouveaurecit.network.dto.EntityResolveResponse
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.IsbnFactsDto
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
import studio.lunabee.nouveaurecit.network.dto.SearchResultsDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty
import java.io.File
import java.util.UUID

/**
 * `EntityCreationModel` (features 0020, iOS 0047, 0049 and 0050): writing into inventaire.io's open
 * database — the one thing the app does that is not about the user's own shelves. It publishes a book
 * inventaire.io lacks, and changes an edition that exists: everything inventaire.io accepts on it, the
 * works it is an edition of, their titles and authors.
 *
 * **Nothing here is optimistic.** An optimistic publication that failed would leave the user believing
 * they had contributed, and one that half-succeeded would leave a work without its edition on a public
 * website. Every call is awaited, and the form stays open until the server has spoken. What a save wrote
 * reaches Room afterwards, through `EntityRepository.applyEditionEdit`.
 *
 * Reads made about a book rather than about a user — the ISBN's language, an edition, its works — go
 * through the cookieless [publicApi]: sending a session to a public endpoint would have the server hand
 * one back for nothing (ADR 0008). Searches and writes go through [api].
 */
class EntityCreationRepository(
    private val api: ApiService,
    private val publicApi: ApiService,
) {
    // Creating a book

    /**
     * What the ISBN says about the book's language, or `null` when the server does not know, the call
     * fails, or the group has no language — the edition is then published **without** a language claim.
     */
    suspend fun editionLanguage(isbn: String): EditionLanguage? {
        val normalized: String = NewBookDraft.normalizeIsbn(isbn)
        if (normalized.isEmpty()) return null
        val facts: IsbnFactsDto = quietly { publicApi.get<IsbnFactsDto>("/api/data/isbn", "isbn" to normalized) } ?: return null
        val uri: String = facts.groupLangUri ?: return null
        val code: String = facts.groupLang ?: return null
        return EditionLanguage(uri = uri, code = code)
    }

    /**
     * Sends the photographed cover and answers the url inventaire.io filed it under — or `null`, which is
     * not worth stopping for: `enrich` already looks for a cover from the ISBN.
     *
     * The url is made **absolute**: the upload answers a path, and `resolve` refuses an edition seed whose
     * `image` is not a url it can fetch (`isUrl` in `sanitize_seed.ts`) — the whole entry, not the picture.
     */
    suspend fun uploadCover(bytes: ByteArray): String? = quietly { upload(bytes) }?.let { ImageUrl.absolute(it) }

    /**
     * The dry run: asks what inventaire.io already knows, **writing nothing**. Answers the uri of a work
     * the server resolved — the edition is missing, not the work. A failure answers `null`: the question is
     * not put, and the publication goes ahead; the server dedupes on its side as best it can.
     */
    suspend fun recogniseWork(draft: NewBookDraft): String? = quietly {
        api.send<_, EntityResolveResponse>("/api/entities/resolve", body = ResolveRequestBuilder.request(draft, create = false))
    }?.resolvedWorkUri

    /**
     * Creates the publishers, collections and people a new edition names that inventaire.io does not have —
     * publishers first, a collection under its publisher — before `resolve` names them by uri. Each one is
     * handed to [onCreated] as it lands, so the caller records it in the draft at once: a failure halfway
     * keeps what exists, and a retry does not create it twice.
     */
    suspend fun createPendingEntities(
        properties: EditionProperties,
        language: String,
        onCreated: (id: UUID, uri: String) -> Unit,
    ) {
        var remaining: EditionProperties = properties
        while (true) {
            val (pending, kind) = remaining.pendingEntities.firstNotNullOfOrNull { pending ->
                EntityCreationKind.of(pending.property, remaining.publisherUri)?.let { pending to it }
            } ?: return
            val uri: String = createEntity(pending.entity.trimmedLabel, language, kind)
            remaining = remaining.entityCreated(pending.entity.id, uri)
            onCreated(pending.entity.id, uri)
        }
    }

    /**
     * Creates the edition — and, as needed, its work and authors — and answers the edition's **canonical**
     * uri, which the inventory item is created from. Never a guessed one: an answer without it throws.
     */
    suspend fun createEdition(draft: NewBookDraft): String {
        val response: EntityResolveResponse = api.send("/api/entities/resolve", body = ResolveRequestBuilder.request(draft, create = true))
        return response.editionUri ?: throw NetworkError.BadResponse()
    }

    // Searching, for the pickers

    /**
     * `/api/search` restricted to one [type] — a publisher, a collection, a person, a language, a work —
     * best match first. Throws: a picker says nothing about a failed search, its « Créer » row stays.
     */
    suspend fun searchEntities(query: String, type: EntitySearchType, limit: Int = 15): List<EntitySearchHit> {
        val trimmed: String = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val response: SearchResultsDto = api.get(
            "/api/search",
            "types" to type.raw,
            "search" to trimmed,
            "lang" to "fr",
            "limit" to "$limit",
            "offset" to "0",
            "exact" to "false",
        )
        return response.results
            .sortedByDescending { it.score ?: 0.0 }
            .map { EntitySearchHit(uri = it.uri, label = it.label, description = it.description, image = ImageUrl.absolute(it.image)) }
    }

    /** « De quelle œuvre est-ce une édition ? »: the works found, each with its authors and year. */
    suspend fun searchWorks(query: String): List<WorkCandidate> = describeCandidates(searchEntities(query, EntitySearchType.Works))

    /**
     * The works a search proposed, completed by what tells them apart: who wrote them, and when. One public
     * `by-uris` call with `relatives=wdt:P50` brings both. When it fails the search's own description
     * stands in: a search is not a place for an error.
     */
    suspend fun describeCandidates(results: List<EntitySearchHit>): List<WorkCandidate> {
        if (results.isEmpty()) return emptyList()
        val response: EditableEditionsDto? = quietly {
            publicApi.get<EditableEditionsDto>(
                "/api/entities/by-uris",
                "uris" to results.joinToString("|") { it.uri },
                "attributes" to "labels|claims",
                "lang" to "fr",
                "relatives" to WikidataProperty.AUTHOR,
            )
        }
        return WorkCandidate.candidates(results, response?.entities.orEmpty())
    }

    // Changing an edition

    /**
     * What inventaire.io holds about the edition, read fresh to open « Modifier l'édition ». The
     * publishers, collections and people its claims name come in the same envelope, asked as relatives;
     * languages are not relatives `by-uris` knows, so those — and anything left unnamed — are asked for in
     * a second call, and keep their uri as a name when it fails.
     *
     * Throws when the answer holds no `inv:` edition — a Wikidata one, or nothing: the form could send nothing.
     */
    suspend fun editableEdition(uri: String): EditionClaims {
        val response: EditableEditionsDto = publicApi.get(
            "/api/entities/by-uris",
            "uris" to uri,
            "attributes" to "info|claims|labels",
            "lang" to "fr",
            "relatives" to NAMED_RELATIVES,
        )
        val entities: Map<String, EntityResultDto> = response.entities
        val edition: EntityResultDto = entities[response.redirects?.get(uri) ?: uri]
            ?: entities.values.firstOrNull { EditionClaims.from(it) != null }
            ?: throw NetworkError.BadResponse()
        val unnamed: EditionClaims = EditionClaims.from(edition) ?: throw NetworkError.BadResponse()

        val labels: MutableMap<String, String> = entities.values
            .mapNotNull { dto -> displayName(dto)?.let { dto.uri to it } }
            .toMap(LinkedHashMap())
        val missing: List<String> = unnamed.properties.entityUris.filter { it !in labels }
        if (missing.isNotEmpty()) {
            val named: EditableEditionsDto? = quietly {
                publicApi.get<EditableEditionsDto>(
                    "/api/entities/by-uris",
                    "uris" to missing.joinToString("|"),
                    "attributes" to "labels",
                    "lang" to "fr",
                )
            }
            named?.entities?.values?.forEach { dto -> displayName(dto)?.let { labels.putIfAbsent(dto.uri, it) } }
        }
        return EditionClaims.from(edition, labels) ?: unnamed
    }

    /**
     * The works an edition is an edition of, in the order asked, with their authors' names and uris — what
     * the form shows and « Modifier l'œuvre » changes. Public; the authors come in the same envelope. A
     * work the answer does not hold is left out rather than failing the form.
     */
    suspend fun describeEditionWorks(uris: List<String>): List<EditionWork> {
        if (uris.isEmpty()) return emptyList()
        val response: EditableEditionsDto = publicApi.get(
            "/api/entities/by-uris",
            "uris" to uris.joinToString("|"),
            "attributes" to "labels|claims",
            "lang" to "fr",
            "relatives" to WikidataProperty.AUTHOR,
        )
        val byUri: Map<String, EntityResultDto> = response.entities.values.associateBy { it.uri } + response.entities
        return uris.mapNotNull { uri ->
            val work: EntityResultDto = byUri[uri] ?: return@mapNotNull null
            val authors: List<NewBookAuthor> = work.claimStrings(WikidataProperty.AUTHOR).mapNotNull { authorUri ->
                byUri[authorUri]?.let { EntityLabel.resolve(it.labels, it.originalLang) }?.let { NewBookAuthor(name = it, uri = authorUri) }
            }
            EditionWork(
                uri = uri,
                title = EntityLabel.resolve(work.labels, work.originalLang).orEmpty(),
                authors = authors,
                titleLanguage = EntityLabel.language(work.labels, work.originalLang),
            )
        }
    }

    /**
     * Runs what the form changed, one request at a time in the order [EditionEdit.nextStep] gives — the
     * picture, the authors, works, publishers, collections and people that do not exist yet, then the
     * claims, then the works' new titles.
     *
     * Unlike a new book's, a new cover is not an ornament here: it may be the whole change asked for, so an
     * upload that does not land is a failure like any other.
     *
     * Answers [EditionSaveResult.Saved], or an [EditionSaveFailure] carrying the edit as far as it got: what
     * landed has moved into it, and is neither sent nor created again.
     */
    suspend fun saveEdition(edit: EditionEdit): EditionSaveResult {
        var current: EditionEdit = edit
        // Every step lands or throws; a step that did neither would loop for ever.
        var budget: Int = MAX_SAVE_STEPS
        return try {
            while (true) {
                val step: EditionEditStep = current.nextStep ?: break
                if (--budget < 0) throw NetworkError.BadResponse()
                current = run(step, current)
            }
            EditionSaveResult.Saved(current)
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            EditionSaveFailure(current, error)
        }
    }

    private suspend fun run(step: EditionEditStep, edit: EditionEdit): EditionEdit = when (step) {
        is EditionEditStep.UploadCover -> {
            val bytes: ByteArray = readFile(step.path) ?: throw NetworkError.BadResponse()
            val hash: String = EntityImageHash.from(upload(bytes)) ?: throw NetworkError.BadResponse()
            edit.coverUploaded(hash)
        }
        is EditionEditStep.CreateAuthor ->
            edit.authorCreated(step.id, createEntity(mapOf(step.language to step.label), mapOf(WikidataProperty.INSTANCE_OF to listOf(HUMAN))))
        is EditionEditStep.CreateWork -> {
            val claims: Map<String, List<String>> = mapOf(
                WikidataProperty.INSTANCE_OF to listOf(LITERARY_WORK),
                WikidataProperty.AUTHOR to step.authorUris,
            )
            edit.workCreated(step.id, createEntity(mapOf(step.language to step.label), claims))
        }
        is EditionEditStep.CreateEntity -> edit.entityCreated(step.id, createEntity(step.label, step.language, step.kind))
        is EditionEditStep.Claim -> {
            api.send<EditionClaimUpdate, OkStatusDto>("/api/entities/update-claim", method = "PUT", body = step.update)
            edit.landed(step.update)
        }
        is EditionEditStep.Label -> {
            api.send<EntityLabelUpdate, OkStatusDto>("/api/entities/update-label", method = "PUT", body = step.update)
            edit.landed(step.update)
        }
    }

    /**
     * Creates a publisher, a collection or a person an edition names, and answers its uri. A collection has
     * no label: its name is a title, and it is created under its publisher, as the website requires.
     */
    suspend fun createEntity(label: String, language: String, kind: EntityCreationKind): String = when (kind) {
        EntityCreationKind.Human -> createEntity(mapOf(language to label), mapOf(WikidataProperty.INSTANCE_OF to listOf(HUMAN)))
        EntityCreationKind.Publisher -> createEntity(mapOf(language to label), mapOf(WikidataProperty.INSTANCE_OF to listOf(PUBLISHER)))
        is EntityCreationKind.Collection -> createEntity(
            labels = emptyMap(),
            claims = mapOf(
                WikidataProperty.INSTANCE_OF to listOf(EDITORIAL_COLLECTION),
                WikidataProperty.TITLE to listOf(label),
                WikidataProperty.PUBLISHER to listOf(kind.publisherUri),
            ),
        )
    }

    /** `POST /api/entities`: one entity created on inventaire.io, answered by the uri it was created under. */
    private suspend fun createEntity(labels: Map<String, String>, claims: Map<String, List<String>>): String =
        api.send<EntityCreationRequest, CreatedEntityDto>("/api/entities", body = EntityCreationRequest(labels, claims)).entity.uri

    /** `POST /api/images/upload`: the path the picture was filed under, `/img/entities/<hash>`. */
    private suspend fun upload(bytes: ByteArray): String? = api.upload(
        path = "/api/images/upload",
        query = listOf("container" to "entities"),
        fieldName = COVER_FIELD,
        fileName = "cover.jpg",
        bytes = bytes,
    )[COVER_FIELD]

    /** The name the form shows for an entity: its label, or — for a collection, which has none — its title. */
    private fun displayName(dto: EntityResultDto): String? =
        EntityLabel.resolve(dto.labels, dto.originalLang) ?: dto.claimString(WikidataProperty.TITLE)

    private suspend fun readFile(path: String): ByteArray? = withContext(Dispatchers.IO) {
        runCatching { File(path).readBytes() }.getOrNull()
    }

    private suspend fun <T> quietly(call: suspend () -> T): T? = try {
        call()
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (_: Exception) {
        null
    }

    private companion object {
        /** The server keys its answer by the form field's name, so this is also the key read back. */
        const val COVER_FIELD: String = "cover"

        /** Every step lands or throws: far more than any form can ask, and a stop for a step that does neither. */
        const val MAX_SAVE_STEPS: Int = 100

        /** `wdt:P31` of what the website creates: a human, a literary work, a publisher, an editorial collection. */
        const val HUMAN: String = "wd:Q5"
        const val LITERARY_WORK: String = "wd:Q47461344"
        const val PUBLISHER: String = "wd:Q2085381"
        const val EDITORIAL_COLLECTION: String = "wd:Q20655472"

        /** The claims of an edition whose values `by-uris` can bring along with their labels: not languages. */
        val NAMED_RELATIVES: String = EditionProperty.all
            .filter { it.searchType != null && it.searchType != EntitySearchType.Languages }
            .joinToString("|") { it.uri }
    }
}
