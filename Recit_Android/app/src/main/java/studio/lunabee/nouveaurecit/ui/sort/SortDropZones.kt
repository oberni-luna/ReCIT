package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect

/**
 * Where a book is let go (feature 0010): every drop target says where it is on screen, and the
 * drop goes to the one under the finger. Targets on a higher [layer] win where they overlap — the
 * panel of books to file floats over the grid, so a card scrolled underneath it is not a target
 * there, and the book goes back to « à ranger ».
 *
 * Bounds are clipped to what is visible (`boundsInRoot`), so a card scrolled out of the grid's
 * viewport cannot catch a drop either.
 */
data class SortDropZone<K>(val key: K, val bounds: Rect, val layer: Int = GRID_LAYER) {
    companion object {
        const val GRID_LAYER: Int = 0
        const val PANEL_LAYER: Int = 1
    }
}

object SortDropZones {
    fun <K> hit(zones: Collection<SortDropZone<K>>, point: Offset): K? =
        zones.filter { it.bounds.contains(point) && !it.bounds.isEmpty }.maxByOrNull { it.layer }?.key
}
