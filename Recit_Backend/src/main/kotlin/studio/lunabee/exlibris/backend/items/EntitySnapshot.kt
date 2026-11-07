package studio.lunabee.exlibris.backend.items

/** An entity's snapshot as stored, under its canonical [uri], with its [works] and when it was [refreshed]. */
data class EntitySnapshot(
    val uri: String,
    val snapshot: ItemSnapshot,
    val works: List<SnapshotWork>,
    val refreshed: Long,
)
