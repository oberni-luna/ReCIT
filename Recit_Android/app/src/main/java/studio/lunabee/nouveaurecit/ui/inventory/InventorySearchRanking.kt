package studio.lunabee.nouveaurecit.ui.inventory

import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.model.Merges

/**
 * `Model/SearchResult/InventorySearchRanking.swift`: the local matches of the unified search, over
 * my copies and my friends', mine first and newest first within each group. The `searchIndex` is
 * already folded at sync; the query is folded here, so « emile zola » finds « Émile Zola ».
 */
object InventorySearchRanking {
    data class Candidate(val id: String, val searchIndex: String, val isMine: Boolean, val created: Double)

    data class Outcome(val matches: List<Candidate>, val totalCount: Int) {
        companion object {
            val None: Outcome = Outcome(emptyList(), 0)
        }
    }

    data class ItemOutcome(val items: List<ItemRow>, val totalCount: Int)

    /** How many matches the section shows before « Tout voir ». */
    const val DISPLAY_LIMIT: Int = 3

    /** No cap — what « Tout voir » asks for, from this same function so both orders agree. */
    const val NO_LIMIT: Int = Int.MAX_VALUE

    /** An empty query matches nothing rather than everything. */
    fun rank(candidates: List<Candidate>, query: String, limit: Int = DISPLAY_LIMIT): Outcome {
        val folded: String = Merges.fold(query)
        if (folded.isEmpty()) return Outcome.None
        val matches: List<Candidate> = candidates
            .filter { it.searchIndex.contains(folded) }
            .sortedWith(compareByDescending<Candidate> { it.isMine }.thenByDescending { it.created })
        return Outcome(matches.take(limit.coerceAtLeast(0)), matches.size)
    }

    fun rankItems(items: List<ItemRow>, query: String, ownerId: String, limit: Int = DISPLAY_LIMIT): ItemOutcome {
        val byId: Map<String, ItemRow> = items.associateBy { it.item.id }
        val outcome: Outcome = rank(
            candidates = byId.values.map { Candidate(it.item.id, it.item.searchIndex, it.item.ownerId == ownerId, it.item.created) },
            query = query,
            limit = limit,
        )
        return ItemOutcome(outcome.matches.mapNotNull { byId[it.id] }, outcome.totalCount)
    }
}
