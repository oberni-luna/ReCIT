package studio.lunabee.exlibris.backend.items

/** What one `bulk-update` writes on each of its books: one of inventaire.io's `updatable` attributes. */
sealed interface ItemChange {
    data class Transaction(
        val mode: TransactionMode,
    ) : ItemChange

    data class Visibility(
        val keys: List<String>,
    ) : ItemChange

    data class Details(
        val text: String,
    ) : ItemChange

    data class Notes(
        val text: String,
    ) : ItemChange

    /** Every étagère the books are on, replacing those they were on. */
    data class Shelves(
        val shelfIds: List<String>,
    ) : ItemChange

    /** Another entity, its snapshot already stored. */
    data class Entity(
        val uri: String,
    ) : ItemChange

    /**
     * An attribute inventaire.io silently leaves alone (`notUpdatable`: `_id`, `owner`, `created`…): the books
     * are still written, their `updated` moved.
     */
    data object Untouched : ItemChange
}
