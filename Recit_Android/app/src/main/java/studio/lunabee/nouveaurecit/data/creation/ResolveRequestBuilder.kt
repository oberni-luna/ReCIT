package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.network.dto.EntityResolveRequest
import java.util.Locale

/**
 * `ResolveRequestBuilder` (feature 0020): what the user typed, into the request that creates a book.
 * Pure, so the rules are asserted against the body that goes on the wire.
 *
 * - The ISBN travels normalized, as `wdt:P212`. It is the only thing the app is certain of.
 * - `wdt:P1476` is the title of *this edition*, not of the work: a translation, a reissue and a boxed
 *   set share a work and disagree about their covers.
 * - An author already on inventaire is named by uri; one being created is described by label. Same
 *   for the work. That one distinction keeps the base free of twins.
 */
object ResolveRequestBuilder {
    private const val ISBN_13: String = "wdt:P212"
    private const val EDITION_TITLE: String = "wdt:P1476"
    private const val LANGUAGE: String = "wdt:P407"
    private const val EDITION_OF: String = "wdt:P629"

    /**
     * The language labels are written in when the ISBN has not answered: the reader's. A wrong label
     * language is a nuisance rather than a falsehood.
     */
    val defaultLabelLanguage: String get() = Locale.getDefault().language.ifEmpty { "fr" }

    /** The request that creates the book — or, with `create = false`, the dry run that only asks. */
    fun request(draft: NewBookDraft, create: Boolean, language: String = defaultLabelLanguage): EntityResolveRequest {
        // What the ISBN says wins over the phone: it knows the book's language, the phone the reader's.
        val labelLanguage: String = draft.language?.code ?: language

        val editionClaims: MutableMap<String, List<String>> = linkedMapOf(
            ISBN_13 to listOf(draft.normalizedIsbn),
            EDITION_TITLE to listOf(draft.trimmedTitle),
        )
        // Omitted rather than guessed: a wrong language on a public edition reads as a checked fact.
        draft.language?.let { editionClaims[LANGUAGE] = listOf(it.uri) }
        // A recognised work is pointed at, not described a second time — that would offer the server
        // a work to create next to the one it just found.
        draft.workUri?.let { editionClaims[EDITION_OF] = listOf(it) }

        // An uploaded cover is offered, never required: `enrich` covers the books nobody photographed.
        val edition = EntityResolveRequest.Seed(claims = editionClaims, image = draft.coverImageUrl)
        val works: List<EntityResolveRequest.Seed>? = if (draft.workUri == null) {
            listOf(EntityResolveRequest.Seed.described(draft.trimmedTitle, labelLanguage))
        } else {
            null
        }
        val author: EntityResolveRequest.Seed = draft.authorUri?.let(EntityResolveRequest.Seed::named)
            ?: EntityResolveRequest.Seed.described(draft.trimmedAuthorName, labelLanguage)

        return EntityResolveRequest(
            entries = listOf(EntityResolveRequest.Entry(edition = edition, works = works, authors = listOf(author))),
            create = create,
            // Even on the dry run: one that comes back with a cover has told us something.
            enrich = true,
            // Half an entry is worse than none: a work without its edition is an orphan on the website.
            strict = true,
        )
    }
}
