package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortSection`: one band of the sorting surface — an étagère that exists on the server, one the user
 * has drafted but not yet created, or the pile of books that are on none.
 *
 * One type rather than three because every rule on the surface treats them alike: a book is dragged
 * out of any of them and into any of them, and the projection's invariant is that it sits in exactly
 * one. Only the write plan has to tell them apart, and it does so on [id].
 *
 * A draft carries no members of its own: membership lives entirely in the change stack, so a draft is
 * a name and an id until the projection fills it.
 */
data class SortSection(
    val id: SortSectionId,
    /**
     * The étagère's name, or `null` for the pile, which has no name of its own. What the pile is
     * called is copy, so it lives in the string resources and is resolved by the screen.
     */
    val name: String?,
    val books: List<SortBook>,
) {
    /** Derived rather than stored, so the count on a card can never disagree with the books under it. */
    val bookCount: Int get() = books.size

    /** The pile reads differently from an étagère — it sits apart and carries no state pill. */
    val isUnshelved: Boolean get() = id == SortSectionId.Unshelved
}
