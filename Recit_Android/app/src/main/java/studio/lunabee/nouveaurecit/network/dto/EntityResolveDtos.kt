package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.Serializable
import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral

/**
 * `EntityResolveRequest`: the body of `POST /api/entities/resolve`, the one endpoint that carries the
 * whole of creating a book on inventaire.io (feature 0020).
 *
 * An entry is three seeds: the edition, the works it is an edition of, and their authors. Each seed
 * either **names** an entity by its uri, or **describes** one by its labels and claims. A uri is
 * reused; a description is matched and, failing a match, created.
 *
 * Optional fields are omitted rather than sent null (`explicitNulls = false`): the server reads a
 * present key as an intention.
 *
 * Verified against `https://inventaire.io/public/api_specs.json` (5.1.1) and the Codeberg source on
 * 2026-10-21.
 */
@Serializable
data class EntityResolveRequest(
    val entries: List<Entry>,
    /** Create what could not be resolved. False for the dry run that only asks what inventaire knows. */
    val create: Boolean,
    /** Let the server look for what it can add by itself — a cover, from the ISBN. */
    val enrich: Boolean,
    /** Refuse the whole entry rather than half-creating it. */
    val strict: Boolean,
) {
    @Serializable
    data class Entry(
        val edition: Seed,
        val works: List<Seed>? = null,
        val authors: List<Seed>? = null,
    )

    /**
     * A uri **or** a description, never usefully both. Only an edition seed carries an [image]. Claims keep
     * their type: a number of pages goes out as a JSON number ([ClaimLiteral]).
     */
    @Serializable
    data class Seed(
        val uri: String? = null,
        val labels: Map<String, String>? = null,
        val claims: Map<String, List<ClaimLiteral>>? = null,
        val image: String? = null,
    ) {
        companion object {
            fun named(uri: String): Seed = Seed(uri = uri)

            fun described(label: String, language: String, claims: Map<String, List<ClaimLiteral>>? = null): Seed =
                Seed(labels = mapOf(language to label), claims = claims)
        }
    }
}

/**
 * `EntityResolveResponse`: the same entries, each seed told apart — `uri` once it is known, `resolved`
 * when the server matched an entity that already existed, `created` when it made one.
 */
@Serializable
data class EntityResolveResponse(val entries: List<Entry> = emptyList()) {
    @Serializable
    data class Entry(
        val edition: Seed? = null,
        val works: List<Seed>? = null,
        val authors: List<Seed>? = null,
    )

    @Serializable
    data class Seed(
        val uri: String? = null,
        val resolved: Boolean? = null,
        val created: Boolean? = null,
    )

    /**
     * A work the server **recognised** — not one it created, not one it merely echoed back. This is what
     * the dry run is for: a work already on inventaire.io means the book is one more edition of it.
     */
    val resolvedWorkUri: String?
        get() = entries.firstOrNull()?.works?.firstOrNull { it.resolved == true }?.uri

    /**
     * The canonical uri of the edition, created or found already there — a book somebody else added a
     * minute ago is the existing one, which is the right answer and not an error.
     */
    val editionUri: String?
        get() = entries.firstOrNull()?.edition?.uri
}

/** `IsbnFactsDTO`: what public `GET /api/data/isbn` answers. Only the group's language is read. */
@Serializable
data class IsbnFactsDto(
    /** `fr` for the `978-2` group. */
    val groupLang: String? = null,
    /** The same language as a wikidata entity — `wd:Q150`. */
    val groupLangUri: String? = null,
)
