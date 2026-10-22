package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortSection.ID`: what a change names a section by, and what the screen keys its cards on.
 *
 * A draft carries a `draft:`-prefixed client id ([SortDraftId]), mirroring ADR 0001's `optimistic:`
 * convention, so a placeholder can never be mistaken for a server document — which matters the moment
 * the write plan decides what to create and what to merely fill.
 */
sealed interface SortSectionId {
    /** An étagère that exists on the server, by its shelf `_id`. */
    data class Shelf(val id: String) : SortSectionId

    /** An étagère the user has drafted on the surface, by its client id. */
    data class Draft(val id: String) : SortSectionId

    /** The books that are on no étagère at all. Exactly one per projection. */
    data object Unshelved : SortSectionId
}
