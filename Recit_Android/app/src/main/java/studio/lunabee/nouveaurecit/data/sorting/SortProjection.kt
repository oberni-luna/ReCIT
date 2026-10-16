package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortProjection`: snapshot + change stack → the sections the sorting surface renders.
 *
 * **It owns one invariant: every book sits in exactly one section.** A drop removes before it adds,
 * which here is not a sequence of two steps but a single assignment in a book → section map — the
 * cheapest possible way to make the rule unbreakable. A book in two sections would be written twice.
 *
 * The store does not hand us a partition: a copy may sit on several étagères (ADR 0003), so the first
 * étagère that claims a book keeps it and the later ones do not list it. First rather than last so the
 * reading is stable under a reordering of the stack.
 *
 * **Order inside a section is arrival order, derived.** The books this session moved into a section
 * come first, the most recent move first; behind them, the books already there, in snapshot order.
 * That is what makes a pile work: its front is the book just filed, and the front is what a drag from
 * the card carries — so a mis-drop is undone by dragging back exactly what was dropped.
 *
 * Recomputed rather than tracked: a tracked target state is how a pill, a recap and a write end up
 * disagreeing. Read it once per state, not once per card.
 */
data class SortProjection(
    /**
     * Every étagère in snapshot order, then every draft in the order it was created, then the pile —
     * always last, and always present, because it is a drop target whether or not it holds anything.
     */
    val sections: List<SortSection>,
) {
    /** The pile, which every projection has. */
    val unshelved: SortSection
        get() = sections.firstOrNull { it.isUnshelved } ?: SortSection(SortSectionId.Unshelved, null, emptyList())

    companion object {
        operator fun invoke(snapshot: SortSnapshot, changes: List<SortChange> = emptyList()): SortProjection {
            // Books keyed by id, first occurrence winning, so a store that somehow held two rows for one
            // `_id` still yields one book on screen.
            val booksById: MutableMap<String, SortBook> = linkedMapOf()
            for (book in snapshot.books) booksById.putIfAbsent(book.id, book)

            // The sections, in reading order. Names are resolved in exactly one place, so a draft named by
            // the stack and an étagère named by the snapshot cannot disagree.
            val sectionIds: MutableList<SortSectionId> = snapshot.shelves.map { SortSectionId.Shelf(it.id) }.toMutableList()
            val namesById: MutableMap<SortSectionId, String> = hashMapOf()
            for (shelf in snapshot.shelves) namesById[SortSectionId.Shelf(shelf.id)] = shelf.name

            // Where each book sits. Assignment, never insertion, is what enforces the invariant.
            val sectionOfBook: MutableMap<String, SortSectionId> = hashMapOf()
            for (shelf in snapshot.shelves) {
                for (bookId in shelf.bookIds) {
                    if (bookId in booksById && bookId !in sectionOfBook) sectionOfBook[bookId] = SortSectionId.Shelf(shelf.id)
                }
            }

            // When this session filed each book where it now sits. Overwritten with every move, so a book
            // moved three times carries the index of its last move only — the one that decided where it is.
            val arrivalOfBook: MutableMap<String, Int> = hashMapOf()

            changes.forEachIndexed { index, change ->
                when (change) {
                    is SortChange.CreateShelf -> {
                        val id: SortSectionId = SortSectionId.Draft(change.draftId)
                        // A second creation under the same id renames rather than adding a twin.
                        if (id !in namesById) sectionIds.add(id)
                        namesById[id] = change.name
                    }
                    is SortChange.MoveBook -> {
                        // A move naming a book or a section the projection does not know is ignored rather
                        // than trapped: an apply rebuilds the snapshot as it goes, and the screen must keep
                        // rendering.
                        val known: Boolean = change.bookId in booksById &&
                            (change.to == SortSectionId.Unshelved || change.to in namesById)
                        if (known) {
                            sectionOfBook[change.bookId] = change.to
                            arrivalOfBook[change.bookId] = index
                        }
                    }
                }
            }

            sectionIds.add(SortSectionId.Unshelved)

            val booksBySection: MutableMap<SortSectionId, MutableList<SortBook>> = hashMapOf()
            for (book in booksById.values) {
                val section: SortSectionId = sectionOfBook[book.id] ?: SortSectionId.Unshelved
                booksBySection.getOrPut(section) { mutableListOf() }.add(book)
            }

            return SortProjection(
                sectionIds.map { id ->
                    SortSection(
                        id = id,
                        name = if (id == SortSectionId.Unshelved) null else namesById[id],
                        books = inArrivalOrder(booksBySection[id].orEmpty(), arrivalOfBook),
                    )
                },
            )
        }

        /**
         * One section's books, arrivals first. A stable partition rather than a sort over a mixed key:
         * the books this session moved here read latest first, everything else keeps snapshot order.
         */
        private fun inArrivalOrder(books: List<SortBook>, arrivals: Map<String, Int>): List<SortBook> {
            val (arrived: List<SortBook>, settled: List<SortBook>) = books.partition { it.id in arrivals }
            return arrived.sortedByDescending { arrivals.getValue(it.id) } + settled
        }
    }
}
