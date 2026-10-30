package studio.lunabee.nouveaurecit.data.lists

import studio.lunabee.nouveaurecit.data.model.EntityListType
import java.text.Collator

/**
 * `Model/Lists/ListMoveDestination.swift`: one list an element can be moved into, as « Déplacer dans une
 * autre liste » offers it — a list of the same type as the one the element is in, never that one itself.
 * A list that already holds the element is offered too, but greyed: inventaire.io answers
 * `alreadyInList` and creates nothing, so moving there would only take the element out of its list.
 */
data class ListMoveDestination(val id: String, val name: String, val alreadyHolds: Boolean) {
    /** A list as the menu needs to know it. */
    data class Candidate(val id: String, val name: String, val type: EntityListType, val uris: Set<String>)

    companion object {
        /** The lists [uri] can be moved into from [currentListId], sorted by name. */
        fun destinations(uri: String, currentListId: String, type: EntityListType, candidates: List<Candidate>): List<ListMoveDestination> {
            val collator: Collator = Collator.getInstance().apply { strength = Collator.SECONDARY }
            return candidates
                .filter { it.id != currentListId && it.type == type }
                .sortedWith { a, b -> collator.compare(a.name, b.name) }
                .map { ListMoveDestination(it.id, it.name, uri in it.uris) }
        }
    }
}
