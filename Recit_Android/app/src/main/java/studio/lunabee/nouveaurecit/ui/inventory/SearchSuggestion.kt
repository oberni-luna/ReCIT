package studio.lunabee.nouveaurecit.ui.inventory

import studio.lunabee.nouveaurecit.data.SearchResult
import studio.lunabee.nouveaurecit.data.model.Merges

/**
 * `Model/SearchResult/SearchSuggestion.swift`: one way on to inventaire.io from the field — books,
 * people, or both. The query is trimmed once, here.
 */
class SearchSuggestion(val kind: Kind, query: String) {
    enum class Kind(val types: Set<SearchResult.Type>) {
        Works(setOf(SearchResult.Type.Works)),
        Humans(setOf(SearchResult.Type.Humans)),
        Everything(setOf(SearchResult.Type.Humans, SearchResult.Type.Works)),
    }

    val query: String = query.trim()

    val types: Set<SearchResult.Type> get() = kind.types

    override fun equals(other: Any?): Boolean = other is SearchSuggestion && other.kind == kind && other.query == query

    override fun hashCode(): Int = 31 * kind.hashCode() + query.hashCode()

    override fun toString(): String = "SearchSuggestion($kind, $query)"

    companion object {
        /** The three suggestions, always books, people, everything. Empty below the threshold. */
        fun suggestions(query: String): List<SearchSuggestion> {
            val trimmed: String = query.trim()
            if (trimmed.length < SearchPhase.MINIMUM_QUERY_LENGTH) return emptyList()
            return Kind.entries.map { SearchSuggestion(it, trimmed) }
        }

        /** What the keyboard's search key sends; `null` below the threshold. */
        fun everything(query: String): SearchSuggestion? {
            val trimmed: String = query.trim()
            if (trimmed.length < SearchPhase.MINIMUM_QUERY_LENGTH) return null
            return SearchSuggestion(Kind.Everything, trimmed)
        }

        /**
         * Where `query` sits in `sentence`, to be drawn in bold — searched from the end and loosely
         * (case and accents folded), since the query ends both sentences and « emile » must still
         * light up « Émile ».
         */
        fun emphasisRange(query: String, sentence: String): IntRange? {
            val needle: String = Merges.fold(query)
            if (needle.isEmpty() || query.length > sentence.length) return null
            for (start in sentence.length - query.length downTo 0) {
                val candidate: String = sentence.substring(start, start + query.length)
                if (Merges.fold(candidate) == needle) return start until start + query.length
            }
            return null
        }
    }
}
