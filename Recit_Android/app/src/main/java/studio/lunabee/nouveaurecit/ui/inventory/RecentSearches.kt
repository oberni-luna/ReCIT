package studio.lunabee.nouveaurecit.ui.inventory

import studio.lunabee.nouveaurecit.data.model.Merges

/**
 * `AppModels/Search/RecentSearchStore.swift`, as pure functions over the stored list: what this
 * account actually sent, most recent first. Per user, on the device only; everything is kept and
 * the screen draws [DISPLAYED_COUNT]. Two spellings folding to the same text are one entry, which
 * moves to the front carrying the spelling last used.
 */
object RecentSearches {
    const val DISPLAYED_COUNT: Int = 3

    /** The `UserPreferences` key holding one account's history. */
    fun preferenceKey(userId: String): String = "RecentSearchStore.searches.$userId"

    /** The slice drawn at the focus of the field. */
    fun displayed(history: List<String>): List<String> = history.take(DISPLAYED_COUNT)

    /** `history` with `query` remembered at its front; unchanged when the query normalises to nothing. */
    fun record(history: List<String>, query: String): List<String> {
        val normalised: String = normalise(query)
        if (normalised.isEmpty()) return history
        val key: String = Merges.fold(normalised)
        return listOf(normalised) + history.filter { Merges.fold(it) != key }
    }

    /** Trimmed, with one space between words whatever was typed between them. */
    fun normalise(query: String): String =
        query.split(Regex("\\s+")).filter(String::isNotEmpty).joinToString(" ")
}
