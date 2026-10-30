package studio.lunabee.nouveaurecit.data.lists

/**
 * `Model/Lists/ListAdditionPlan.swift`: what adding to a list comes down to, once the reader has said
 * which works they want — the ones the list does not hold yet, or, when it holds them all, the one to
 * show instead.
 *
 * **inventaire.io keeps a work only once in a list.** `PUT /api/lists/add-elements` answers an uri the
 * list already holds with `alreadyInList` and creates nothing, so the uris already there are left out of
 * the request, and when nothing is left the reader is taken to the book.
 */
sealed interface ListAdditionPlan {
    /** Add these uris, in the order they were chosen. */
    data class Add(val uris: List<String>) : ListAdditionPlan

    /** Every chosen uri is already in the list: show this one. */
    data class AlreadyInList(val uri: String) : ListAdditionPlan

    /** Nothing was chosen. */
    data object Nothing : ListAdditionPlan

    companion object {
        fun plan(chosen: List<String>, existing: Set<String>): ListAdditionPlan {
            val distinct: List<String> = chosen.distinct()
            val first: String = distinct.firstOrNull() ?: return Nothing
            val missing: List<String> = distinct.filter { it !in existing }
            return if (missing.isEmpty()) AlreadyInList(first) else Add(missing)
        }
    }
}
