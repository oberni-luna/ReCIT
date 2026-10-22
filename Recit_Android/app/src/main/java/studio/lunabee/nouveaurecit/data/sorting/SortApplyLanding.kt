package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortApplyLanding`: one operation the server confirmed, folded back into the session — the snapshot
 * gains what landed, and the stack is left holding exactly the work still to do.
 *
 * **This is what makes a failure halfway survivable.** The apply stops where it broke and nothing is
 * rolled back, so the remainder has to be *in the stack*: the pills, the recap and the button labels
 * are derived from it, and pressing « Enregistrer » again sends the rest.
 *
 * **Re-sending the whole stack would be wrong.** `add-items` is idempotent; a *creation* is not —
 * replaying one that succeeded makes a second étagère of the same name. So a creation leaves the stack
 * the instant the server confirms it, even when the membership write after it fails.
 *
 * **The reduction is stateless: the stack *is* the target.** The rebuilt stack is the difference between
 * the snapshot the confirmation just updated and the projection the user arranged, with a created
 * draft's section swapped for the étagère the server gave it. A draft that ends up holding nothing
 * stays in the rebuilt stack, so a resume still creates it.
 */
data class SortApplyLanding(
    /** The library as the server now holds it, as far as this run knows. */
    val snapshot: SortSnapshot,
    /** Exactly the work that is left. Empty once everything has landed. */
    val changes: List<SortChange>,
) {
    /**
     * What the server said it did. One per call actually made: a group is create, then remove, then add,
     * and each lands on its own so a failure at the second step keeps the first out of the stack.
     */
    sealed interface Confirmation {
        /** A drafted étagère now exists, under the id the server assigned it. */
        data class ShelfCreated(val draftId: String, val shelfId: String, val name: String) : Confirmation

        /** Books that are no longer on this étagère. */
        data class BooksRemoved(val shelfId: String, val bookIds: List<String>) : Confirmation

        /** Books that are now on this étagère. */
        data class BooksAdded(val shelfId: String, val bookIds: List<String>) : Confirmation
    }

    companion object {
        operator fun invoke(snapshot: SortSnapshot, changes: List<SortChange>, confirmed: Confirmation): SortApplyLanding {
            // Where the user means every book to end up, and which drafts are still owed an étagère —
            // read off the projection, so "a book sits in exactly one section" is the screen's own rule.
            val target: SortProjection = SortProjection(snapshot, changes)
            val destination: MutableMap<String, SortSectionId> = hashMapOf()
            val pendingDrafts: MutableList<Pair<String, String>> = mutableListOf()
            for (section in target.sections) {
                if (section.isUnshelved) continue
                for (book in section.books) destination[book.id] = section.id
                val id: SortSectionId = section.id
                if (id is SortSectionId.Draft) pendingDrafts.add(id.id to section.name.orEmpty())
            }

            var shelves: List<SortSnapshot.Shelf> = snapshot.shelves

            when (confirmed) {
                is Confirmation.ShelfCreated -> {
                    // Appended rather than slotted into name order: the draft was the last section before
                    // the pile and the étagère it became stays there, so nothing jumps during the run.
                    if (shelves.none { it.id == confirmed.shelfId }) {
                        shelves = shelves + SortSnapshot.Shelf(confirmed.shelfId, confirmed.name, emptyList())
                    }
                    val draft: SortSectionId = SortSectionId.Draft(confirmed.draftId)
                    destination.replaceAll { _, section -> if (section == draft) SortSectionId.Shelf(confirmed.shelfId) else section }
                    pendingDrafts.removeAll { it.first == confirmed.draftId }
                }
                is Confirmation.BooksRemoved -> {
                    val removed: Set<String> = confirmed.bookIds.toSet()
                    shelves = shelves.map { shelf ->
                        if (shelf.id != confirmed.shelfId) shelf else shelf.copy(bookIds = shelf.bookIds.filter { it !in removed })
                    }
                }
                is Confirmation.BooksAdded -> {
                    shelves = shelves.map { shelf ->
                        if (shelf.id != confirmed.shelfId) {
                            shelf
                        } else {
                            val held: Set<String> = shelf.bookIds.toSet()
                            shelf.copy(bookIds = shelf.bookIds + confirmed.bookIds.filter { it !in held })
                        }
                    }
                }
            }

            val landed: SortSnapshot = SortSnapshot(shelves, snapshot.books)
            val library: SortProjection = SortProjection(landed)

            val current: MutableMap<String, SortSectionId> = hashMapOf()
            for (section in library.sections) {
                if (section.isUnshelved) continue
                for (book in section.books) current[book.id] = section.id
            }

            // Creations first: the projection ignores a move naming a section it does not know, so a stack
            // that filled a draft before declaring it would lose its books. Every draft still owed, filled
            // or not: an empty étagère is created too.
            val rebuilt: MutableList<SortChange> = pendingDrafts.mapTo(mutableListOf()) { (id, name) -> SortChange.CreateShelf(id, name) }
            for (book in library.sections.flatMap { it.books }) {
                val origin: SortSectionId = current[book.id] ?: SortSectionId.Unshelved
                val wanted: SortSectionId = destination[book.id] ?: SortSectionId.Unshelved
                if (origin != wanted) rebuilt.add(SortChange.MoveBook(book.id, origin, wanted))
            }

            return SortApplyLanding(landed, rebuilt)
        }
    }
}
