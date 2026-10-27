package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.network.dto.EntityResolveRequest
import java.util.Locale

/**
 * `ResolveRequestBuilder` (features 0020, iOS 0047 and 0050): what the user typed, into the request that
 * creates a book. Pure, so the rules are asserted against the body that goes on the wire.
 *
 * - The ISBN travels normalized, as `wdt:P212`. It is the only thing the app is certain of.
 * - Everything else said about the edition — subtitle, publisher, date, language, format, contributors,
 *   identifiers, links — travels in the edition seed, each entity by its uri: the ones to create are
 *   created before this request is built (`EntityCreationRepository.createPendingEntities`).
 * - `wdt:P1476` is the title of *this edition*, not of the work: a translation, a reissue and a boxed
 *   set share a work and disagree about their covers.
 * - An author already on inventaire is named by uri; one being created is described by label. Same for
 *   the work. That one distinction keeps the base free of twins.
 * - A work that exists is named, never left out, and sends no author: it has its own.
 */
object ResolveRequestBuilder {
    private const val ISBN_13: String = "wdt:P212"
    private const val EDITION_TITLE: String = "wdt:P1476"
    private const val SUBTITLE: String = "wdt:P1680"
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

        // The catalogue's values first, then what this builder decides about.
        val editionClaims: MutableMap<String, List<ClaimLiteral>> = LinkedHashMap(draft.properties.claims)
        editionClaims[ISBN_13] = listOf(ClaimLiteral.Text(draft.normalizedIsbn))
        editionClaims[EDITION_TITLE] = listOf(ClaimLiteral.Text(draft.trimmedTitle))
        if (draft.trimmedSubtitle.isNotEmpty()) editionClaims[SUBTITLE] = listOf(ClaimLiteral.Text(draft.trimmedSubtitle))

        // The form's language, which the ISBN filled in. Omitted rather than guessed when neither said: a
        // wrong language on a public edition reads as a checked fact.
        if (LANGUAGE !in editionClaims) draft.language?.let { editionClaims[LANGUAGE] = listOf(ClaimLiteral.Text(it.uri)) }

        // A known work is pointed at, not described a second time — that would offer the server a work to
        // create next to the one it just found.
        draft.workUri?.let { editionClaims[EDITION_OF] = listOf(ClaimLiteral.Text(it)) }

        // An uploaded cover is offered, never required: `enrich` covers the books nobody photographed.
        val edition = EntityResolveRequest.Seed(claims = editionClaims, image = draft.coverImageUrl)

        // A work that exists is named, never left out. An entry with no work seed is not an entry without
        // a work: the server builds one from the edition's title (`sanitize_entry.ts`), which can then match
        // another work or be created beside the one claimed above.
        val works: List<EntityResolveRequest.Seed> = listOf(
            draft.workUri?.let(EntityResolveRequest.Seed::named)
                ?: EntityResolveRequest.Seed.described(draft.workLabel, labelLanguage),
        )

        // Named as soon as someone who exists was picked — merging two authors is not something a phone can
        // undo. And only for a work being created: an author seed beside an existing work would still be
        // resolved, and failing that created, on its own (`create_unresolved_entry.ts`).
        val authors: List<EntityResolveRequest.Seed>? = if (draft.workUri != null) {
            null
        } else {
            draft.namedAuthors.map { author ->
                author.uri?.let(EntityResolveRequest.Seed::named) ?: EntityResolveRequest.Seed.described(author.trimmedName, labelLanguage)
            }
        }

        return EntityResolveRequest(
            entries = listOf(EntityResolveRequest.Entry(edition = edition, works = works, authors = authors)),
            create = create,
            // Even on the dry run: one that comes back with a cover has told us something.
            enrich = true,
            // Half an entry is worse than none: a work without its edition is an orphan on the website.
            strict = true,
        )
    }
}
