package studio.lunabee.nouveaurecit.data.lists

/**
 * `ListCoverFlowScreen.keepSelection(from:to:)`: where a list's selection goes when the list changes
 * under it. The selection is a uri, so an element whose optimistic id is replaced by the server's stays
 * selected.
 *
 * The uri an add asked for wins as soon as the list holds it; else the selection stays where it is;
 * else it takes the place of the element that left, or the last one.
 */
object CoverFlowSelection {
    data class Result(val selected: String?, val requested: String?)

    fun next(oldUris: List<String>, newUris: List<String>, selected: String?, requested: String?): Result {
        if (requested != null && requested in newUris) return Result(requested, null)
        if (selected == null) return Result(newUris.firstOrNull(), requested)
        if (selected in newUris) return Result(selected, requested)
        if (newUris.isEmpty()) return Result(null, requested)
        val formerIndex: Int = oldUris.indexOf(selected).coerceAtLeast(0)
        return Result(newUris[minOf(formerIndex, newUris.size - 1)], requested)
    }
}
