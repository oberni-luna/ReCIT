package studio.lunabee.nouveaurecit.data.scan

/**
 * `ScannedBook` (feature 0007): what the result row draws of an edition the camera recognised.
 *
 * [uri] is the edition's canonical uri (`inv:…`, `wd:…`) as inventaire.io answered it, never the
 * `isbn:…` uri that was asked for — the ownership check matches on it, and matching the requested
 * uri would never fire.
 */
data class ScannedBook(
    val uri: String,
    val title: String,
    val authors: List<String>,
    val coverImageUrl: String?,
    /** The barcode this book was resolved from. */
    val code: String,
) {
    val authorsLine: String get() = authors.joinToString(", ")

    companion object {
        /** Drawn as a skeleton while a lookup runs, so the row keeps its height. */
        val Placeholder: ScannedBook = ScannedBook(
            uri = "",
            title = "Le livre que vous scannez",
            authors = listOf("Prénom Nom"),
            coverImageUrl = null,
            code = "",
        )
    }
}
