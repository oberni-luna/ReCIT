package studio.lunabee.exlibris.backend.items

/**
 * A work a snapshot names, with the claims `inventory-view` groups works by: `wdt:P50`, `wdt:P136`, `wdt:P921`.
 * `null` is a claim the work lacks, which inventaire.io files under `unknown`.
 */
data class SnapshotWork(
    val uri: String,
    val authors: List<String>?,
    val genres: List<String>?,
    val subjects: List<String>?,
)
