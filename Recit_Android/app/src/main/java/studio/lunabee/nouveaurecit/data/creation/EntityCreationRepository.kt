package studio.lunabee.nouveaurecit.data.creation

import kotlinx.coroutines.CancellationException
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.EntityResolveResponse
import studio.lunabee.nouveaurecit.network.dto.IsbnFactsDto

/**
 * `EntityCreationModel` (feature 0020): writing into inventaire.io's open database — the one thing the
 * app does that is not about the user's own shelves.
 *
 * **Nothing here is optimistic.** An optimistic publication that failed would leave the user believing
 * they had contributed, and one that half-succeeded would leave a work without its edition on a public
 * website. Every call is awaited, and the form stays open until the server has spoken.
 *
 * [publicApi] carries the one call made about a book rather than about a user: `GET /api/data/isbn` is
 * public, and sending a session to it would have the server hand one back for nothing (ADR 0008).
 */
class EntityCreationRepository(
    private val api: ApiService,
    private val publicApi: ApiService,
) {
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
     * not worth stopping for: `enrich` already looks for a cover from the ISBN, so an upload that does not
     * land costs a picture and nothing else.
     */
    suspend fun uploadCover(bytes: ByteArray): String? = quietly {
        api.upload(
            path = "/api/images/upload",
            query = listOf("container" to "entities"),
            fieldName = COVER_FIELD,
            fileName = "cover.jpg",
            bytes = bytes,
        )[COVER_FIELD]
    }

    /**
     * The dry run: asks what inventaire.io already knows, **writing nothing**. Answers the uri of a work
     * the server resolved — the edition is missing, not the work. A failure answers `null`: the question
     * is not put, and the publication goes ahead; the server dedupes on its side as best it can.
     */
    suspend fun recogniseWork(draft: NewBookDraft): String? = quietly {
        api.send<_, EntityResolveResponse>("/api/entities/resolve", body = ResolveRequestBuilder.request(draft, create = false))
    }?.resolvedWorkUri

    /**
     * Creates the edition — and, as needed, its work and author — and answers the edition's **canonical**
     * uri, which the inventory item is created from. Never a guessed one: an answer without it throws.
     */
    suspend fun createEdition(draft: NewBookDraft): String {
        val response: EntityResolveResponse = api.send("/api/entities/resolve", body = ResolveRequestBuilder.request(draft, create = true))
        return response.editionUri ?: throw NetworkError.BadResponse()
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
    }
}
