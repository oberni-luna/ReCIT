package studio.lunabee.nouveaurecit.ui.inventory

import studio.lunabee.nouveaurecit.data.SyncStatus
import kotlin.math.roundToInt

/** `InventoryFirstSyncState` (feature 0027): where a user's first inventory sync stands. */
sealed interface FirstSyncState {
    /** Synced at least once: the local store is the inventory. */
    data object Synced : FirstSyncState

    /** Never synced and not running — queued, or the last attempt failed. */
    data object Waiting : FirstSyncState

    data class Running(val progress: SyncStatus.Progress) : FirstSyncState

    /** The bar's value, or `null` while the total is not announced yet. */
    val fraction: Float? get() = (this as? Running)?.progress?.fraction

    /** The banner's trailing figure, once the total is known. */
    val percent: Int? get() = fraction?.let { (it * 100).roundToInt() }

    companion object {
        fun from(lastInventorySync: Double?, progress: SyncStatus.Progress?): FirstSyncState = when {
            lastInventorySync != null -> Synced
            progress != null -> Running(progress)
            else -> Waiting
        }
    }
}
