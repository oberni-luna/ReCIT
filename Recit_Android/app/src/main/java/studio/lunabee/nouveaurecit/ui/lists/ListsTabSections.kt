package studio.lunabee.nouveaurecit.ui.lists

import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.db.UserEntity

/**
 * `ListsTabSections`: what the Lists tab shows, from every list the store holds — « Mes listes », by name,
 * then « Dans mon réseau », my friends' lists, the most recently changed first (a list never changed counts
 * from the day it was made).
 *
 * A friend is one of [of]'s `friends`, read from the `.friend` relations: a stranger whose profile I opened
 * has lists in the store too, and they stay on that profile. [matching] keeps the lists whose name holds the
 * text, in both sections.
 */
data class ListsTabSections(
    val mine: List<ListWithElements>,
    val network: List<NetworkListEntry>,
) {
    val isEmpty: Boolean get() = mine.isEmpty() && network.isEmpty()

    /** Both sections' lists, mine first — the ones whose covers the tab needs. */
    val lists: List<ListWithElements> get() = mine + network.map { it.list }

    fun matching(query: String): ListsTabSections = ListsTabSections(
        mine = mine.filter { ListsPresentation.nameMatches(it.list.name, query) },
        network = network.filter { ListsPresentation.nameMatches(it.list.list.name, query) },
    )

    companion object {
        fun of(lists: List<ListWithElements>, myUserId: String?, friends: List<UserEntity>): ListsTabSections {
            val friendsById: Map<String, UserEntity> = friends.associateBy { it.id }
            return ListsTabSections(
                mine = ListsPresentation.filter(lists.filter { it.list.isCreatedByMe(myUserId) }, query = ""),
                network = lists
                    .mapNotNull { entry ->
                        val owner: UserEntity? = entry.list.creatorId?.takeIf { it != myUserId }?.let(friendsById::get)
                        owner?.let { NetworkListEntry(entry, it) }
                    }
                    .sortedByDescending { it.list.list.updated ?: it.list.list.created },
            )
        }
    }
}
