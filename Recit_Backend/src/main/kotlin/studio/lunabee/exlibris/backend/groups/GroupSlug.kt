package studio.lunabee.exlibris.backend.groups

import studio.lunabee.exlibris.backend.db.DocumentId

/** A group's slug and the names that make one, inventaire.io's `slugify.ts`, `get_next_slug_candidate.ts`. */
object GroupSlug {
    private const val NAME_MAX_LENGTH: Int = 80
    private val separators: Regex = Regex("""(\s+|\.)""")
    private val dashes: Regex = Regex("-+")
    private val notLetters: Regex = Regex("""[^\p{L}-]""")
    private val endDashes: Regex = Regex("(^-|-$)")

    /** Letters and dashes only: digits and punctuation go, as on inventaire.io. */
    fun of(name: String): String =
        name
            .trim()
            .lowercase()
            .replace(separators, "-")
            .replace(dashes, "-")
            .replace(notLetters, "")
            .replace(endDashes, "")

    /** `slug`, then `slug.1`, `slug.2`…: what is tried until no other group holds it. */
    fun candidates(name: String): Sequence<String> {
        val slug: String = of(name)
        return sequenceOf(slug) + generateSequence(1) { it + 1 }.map { "$slug.$it" }
    }

    /** inventaire.io's `groupValidations.name`: 1 to 80 characters, a slug left, neither looking like an id. */
    fun isValidName(name: String): Boolean {
        val slug: String = of(name)
        return name.length in 1..NAME_MAX_LENGTH &&
            slug.isNotEmpty() &&
            !DocumentId.isValid(name) &&
            !DocumentId.isValid(slug)
    }
}
