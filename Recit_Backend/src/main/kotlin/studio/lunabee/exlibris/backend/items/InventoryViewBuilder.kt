package studio.lunabee.exlibris.backend.items

/**
 * inventaire.io's `bundleViewData` and `buildInvertedClaimTree`, from the stored snapshots rather than its entities:
 * a book is filed under its entity's works, or under its entity when the snapshot names none.
 */
object InventoryViewBuilder {
    private const val UNKNOWN: String = "unknown"

    /** [items] the newest first; [worksByEntity] each entity's works, in its snapshot's order. */
    fun build(
        items: List<ViewItem>,
        worksByEntity: Map<String, List<SnapshotWork>>,
    ): InventoryView {
        val byWork: MutableMap<String, MutableList<String>> = linkedMapOf()
        val byOwner: MutableMap<String, MutableMap<String, MutableList<String>>> = linkedMapOf()
        items.forEach { item ->
            val workUris: List<String> =
                worksByEntity[item.entity].orEmpty().map { it.uri }.ifEmpty {
                    listOf(
                        item.entity,
                    )
                }
            workUris.forEach { workUri ->
                byWork.getOrPut(workUri) { mutableListOf() } += item.id
                byOwner.getOrPut(item.owner) { linkedMapOf() }.getOrPut(workUri) { mutableListOf() } += item.id
            }
        }
        val works: List<SnapshotWork> =
            items.flatMap { worksByEntity[it.entity].orEmpty() }.distinctBy { it.uri }
        return InventoryView(
            worksTree =
                WorksTree(
                    author = invert(works) { it.authors },
                    genre = invert(works) { it.genres },
                    subject = invert(works) { it.subjects },
                    owner = byOwner,
                ),
            workUriItemsMap = byWork,
            itemsByDate = items.map { it.id },
            totalItems = items.size,
        )
    }

    private fun invert(
        works: List<SnapshotWork>,
        claim: (SnapshotWork) -> List<String>?,
    ): Map<String, List<String>> {
        val tree: MutableMap<String, MutableList<String>> = linkedMapOf()
        works.forEach { work ->
            (claim(work) ?: listOf(UNKNOWN)).forEach { value -> tree.getOrPut(value) { mutableListOf() } += work.uri }
        }
        return tree
    }
}
