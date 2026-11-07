package studio.lunabee.exlibris.backend.items

/** Whose books an `inventory-view` gathers: a reader's, an étagère's, or a group's members'. */
sealed interface InventoryScope {
    /** [userId]'s books the viewer may see; with [withoutShelf], only those on no étagère. */
    data class Owner(
        val userId: String,
        val withoutShelf: Boolean,
    ) : InventoryScope

    /** The books on [shelfId] the viewer may see. */
    data class OnShelf(
        val shelfId: String,
    ) : InventoryScope

    /**
     * The books of a group's [memberIds] with one of [keys]: `public`, and for a member of the group `groups` and
     * its `group:<id>` too (`getAuthorizedItemsByGroup`) — not what a friendship would show.
     */
    data class Group(
        val memberIds: List<String>,
        val keys: List<String>,
    ) : InventoryScope
}
