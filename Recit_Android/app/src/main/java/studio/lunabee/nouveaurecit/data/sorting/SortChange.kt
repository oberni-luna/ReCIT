package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortChange`: one entry of the sorting session's change stack. Two cases suffice for everything the
 * surface can do — bring an étagère into existence, and move a book from one section to another.
 *
 * **The working state is a stack, not a mutable target state.** Both derivations the surface depends
 * on — the projection it renders and the write plan it executes — are pure functions of the snapshot
 * and this stack, which is what lets a pill, a recap and a write agree by construction.
 *
 * A move carries its **origin** as well as its destination even though the projection only needs the
 * destination: coalescing needs it, and deriving it from a re-run of the projection would make the
 * reduction depend on the snapshot — exactly the coupling the stack exists to avoid.
 */
sealed interface SortChange {
    /** A new étagère, named but not yet written. [draftId] is a [SortDraftId]. */
    data class CreateShelf(val draftId: String, val name: String) : SortChange

    /** A book leaves one section for another. [bookId] is the item's server `_id`. */
    data class MoveBook(val bookId: String, val from: SortSectionId, val to: SortSectionId) : SortChange

    companion object {
        /**
         * One drop, as a change — or nothing at all when the book is dropped back on the section it
         * was dragged from.
         *
         * The no-op belongs here because it is a rule about the stack, and the stack is what the
         * buttons are derived from: a change that changes nothing would still make « Enregistrer »
         * live, and the screen would be offering to discard work that does not exist.
         */
        fun move(bookId: String, from: SortSectionId, to: SortSectionId): SortChange? =
            if (from == to) null else MoveBook(bookId, from, to)

        /**
         * One étagère created on the spot, and the book that was dropped onto the tile that created
         * it — one gesture, as the changes it amounts to.
         *
         * **Both or neither, creation first.** A move naming a draft that was never created is a move
         * the projection ignores: the book would sit where it always was while the screen claimed
         * otherwise.
         *
         * [from] is where the book sits *now*, and `null` when the projection does not know the book —
         * in which case the étagère is still created, since naming one is an instruction of its own.
         */
        fun creation(
            draftId: String,
            name: String,
            filling: String? = null,
            from: SortSectionId? = null,
        ): List<SortChange> {
            val creation: SortChange = CreateShelf(draftId, name)
            if (filling == null || from == null) return listOf(creation)
            val move: SortChange = move(filling, from, SortSectionId.Draft(draftId)) ?: return listOf(creation)
            return listOf(creation, move)
        }
    }
}
