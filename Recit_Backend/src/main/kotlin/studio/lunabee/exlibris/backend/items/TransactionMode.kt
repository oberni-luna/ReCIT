package studio.lunabee.exlibris.backend.items

/** What a book is offered for, inventaire.io's `itemTransactionModes`; [storedName] as the apps send it. */
enum class TransactionMode(
    val storedName: String,
) {
    GIVING("giving"),
    LENDING("lending"),
    SELLING("selling"),
    INVENTORYING("inventorying"),
    ;

    companion object {
        fun of(storedName: String): TransactionMode? = entries.firstOrNull { it.storedName == storedName }
    }
}
