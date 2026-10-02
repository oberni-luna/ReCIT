package studio.lunabee.nouveaurecit.ui.inventory

/**
 * `Model/SearchResult/SearchPhase.swift`: what the inventory's search surface shows right now,
 * from whether the field is open, what has been typed, and whether a search was sent for exactly
 * that text. Pure, so the rule is driven by values in a test instead of by a keyboard.
 *
 * It owns the three-character threshold, written nowhere else.
 */
sealed interface SearchPhase {
    /** The field is open and empty: the recent searches have the screen. */
    data object Recents : SearchPhase

    /** One or two characters — below the threshold. Nothing new appears. */
    data class Typing(override val query: String) : SearchPhase

    /** Three characters or more: the local matches and the ways on to inventaire.io. */
    data class Suggesting(override val query: String) : SearchPhase

    /** A search was sent for this exact query: its results have the screen. */
    data class Results(override val query: String) : SearchPhase

    /** The trimmed query this phase carries; `Recents` carries none. */
    val query: String? get() = null

    /** The query the local section matches against: from three characters on, and on results. */
    val localQuery: String?
        get() = when (this) {
            is Suggesting -> query
            is Results -> query
            else -> null
        }

    companion object {
        /** How many characters a query needs before the screen offers anything beyond the recents. */
        const val MINIMUM_QUERY_LENGTH: Int = 3

        /**
         * The phase the screen is in, or `null` when there is no search surface at all. A submitted
         * query outranks the focus — sending a search hides the keyboard, and the results have to
         * survive that; editing the query afterwards no longer matches, which leaves `Results`.
         */
        fun current(isFocused: Boolean, query: String, submittedQuery: String?): SearchPhase? {
            val trimmed: String = query.trim()
            if (submittedQuery != null && trimmed.isNotEmpty() && submittedQuery.trim() == trimmed) {
                return Results(trimmed)
            }
            if (!isFocused) return null
            return when {
                trimmed.length >= MINIMUM_QUERY_LENGTH -> Suggesting(trimmed)
                trimmed.isEmpty() -> Recents
                else -> Typing(trimmed)
            }
        }
    }
}
