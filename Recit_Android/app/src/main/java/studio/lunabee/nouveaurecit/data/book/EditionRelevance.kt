package studio.lunabee.nouveaurecit.data.book

/**
 * `Model/Books/EditionRelevance.swift`: which edition of a work the app opens when a search
 * result is tapped. `/api/search` cannot return editions, so the app picks one instead of asking
 * which of the 66 editions of Dune the reader meant (ADR 0002, Move 3).
 *
 * The decisions the iOS file states, kept as they are:
 * 1. **A ladder, not a score.** The first non-empty [Tier] wins outright.
 * 2. **Having a title means having one on screen** — asked through `Merges.editionTitle`, the
 *    resolution the edition row itself uses, not through the `wdt:P1476` claim alone.
 * 3. **A box of several books loses to a single one**, decided before ownership; an omnibus still
 *    answers when every candidate of the winning rung is one.
 * 4. **Being held only breaks ties inside the tier that won.**
 * 5. **There is no rung below "has a title"**: reaching the end of the ladder is an answer (`null`).
 */
object EditionRelevance {
    /** An edition reduced to what choosing needs — built from the DTOs, never from stored rows. */
    data class Candidate(
        /** The edition's uri — `inv:…` or `wd:…`. */
        val id: String,
        /** ISO code of the edition's own language (`originalLang`, mirroring `wdt:P407`). */
        val lang: String?,
        val hasTitle: Boolean,
        val hasCover: Boolean,
        /** A copy of this edition is already on this device — mine or a friend's. */
        val isHeld: Boolean = false,
        /** One book rather than a box: `wdt:P629` names a single work. */
        val isSingleWork: Boolean = true,
    )

    /** The rungs, in order. A lower rung can never outrank a higher one. */
    enum class Tier {
        /** My language, with a title, with a cover. */
        PreferredComplete,

        /** My language, with a title. */
        PreferredTitled,

        /** The work's own language, with a title and a cover — for a work never translated. */
        OriginalComplete,

        /** Anything with a title, in any language. The last rung, deliberately. */
        Titled,
        ;

        fun matches(candidate: Candidate, preferredLang: String, originalLang: String?): Boolean = when (this) {
            PreferredComplete -> candidate.lang == preferredLang && candidate.hasTitle && candidate.hasCover
            PreferredTitled -> candidate.lang == preferredLang && candidate.hasTitle
            // Guarded rather than compared: a null original language must not match unknown ones.
            OriginalComplete -> originalLang != null && candidate.lang == originalLang && candidate.hasTitle && candidate.hasCover
            Titled -> candidate.hasTitle
        }
    }

    /**
     * The edition to open, or `null` when there is none worth opening. Deterministic: after the two
     * tie-breaks, the first candidate left answers, in the order the caller supplied.
     */
    fun best(candidates: List<Candidate>, preferredLang: String, originalLang: String? = null): Candidate? {
        for (tier in Tier.entries) {
            val reached: List<Candidate> = candidates.filter { tier.matches(it, preferredLang, originalLang) }
            if (reached.isEmpty()) continue
            val singles: List<Candidate> = reached.filter { it.isSingleWork }
            val shortlist: List<Candidate> = singles.ifEmpty { reached }
            return shortlist.firstOrNull { it.isHeld } ?: shortlist.first()
        }
        return null
    }
}
