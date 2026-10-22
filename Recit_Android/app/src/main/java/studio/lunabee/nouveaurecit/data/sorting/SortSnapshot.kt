package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortSnapshot`: the library as it stood when the sorting surface opened — every étagère, every
 * book, and which books each étagère holds — in value types, frozen.
 *
 * Frozen because the surface is a **draft, not a display** (see [SortSession.load]): nothing here
 * refers to a Room row, so the projection over it is pure and testable without a store.
 *
 * Membership is kept as the store gives it — ids per étagère, possibly overlapping, since a copy may
 * sit on several étagères (ADR 0003). Making that overlap a partition is [SortProjection]'s job: the
 * snapshot's contract is to say what the server holds, and one that quietly dropped a membership
 * would be lying about it.
 */
data class SortSnapshot(
    /** Every étagère of the user, in the order the screen should show them. */
    val shelves: List<Shelf> = emptyList(),
    /**
     * Every book of the user's inventory, in the order the screen should show them. Order within a
     * section is not part of the session's state, so this one order is what every section reads in.
     */
    val books: List<SortBook> = emptyList(),
) {
    /** One étagère, reduced to what sorting needs of it: its name and what the store says is on it. */
    data class Shelf(
        /** The server shelf `_id`. */
        val id: String,
        val name: String,
        /** The inventory item `_id`s the store links to this étagère. May overlap another étagère's. */
        val bookIds: List<String>,
    )

    companion object {
        /** What the surface holds before its opening sync has landed. */
        val Empty: SortSnapshot = SortSnapshot()
    }
}
