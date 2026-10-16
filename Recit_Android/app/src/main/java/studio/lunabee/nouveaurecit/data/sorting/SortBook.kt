package studio.lunabee.nouveaurecit.data.sorting

/**
 * `AutoSortBook`, reduced to what the manual sorting surface needs: one copy of my inventory, as a
 * value rather than a Room row, so the projection, the write plan and the landing can be exercised
 * without a store.
 *
 * It carries the cover and the authors only so the surface can show a book the user recognises; no
 * reduction reads them. The genres the iOS type also carries are left out with automatic sorting.
 *
 * [id] is the item's server `_id`: the write files by it, so it is the identity.
 */
data class SortBook(
    val id: String,
    val title: String,
    val authors: String = "",
    val coverImageUrl: String? = null,
)
