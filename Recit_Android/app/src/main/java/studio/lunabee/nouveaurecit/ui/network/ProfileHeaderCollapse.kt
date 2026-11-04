package studio.lunabee.nouveaurecit.ui.network

import kotlin.math.floor

/**
 * `ProfileHeaderCollapse`: how a reader's profile header folds as a page scrolls, in pixels. [distance]
 * is the scroll that takes it from its full size to its compact one — the picture's shrink, the name's
 * and the rise into the bar's row.
 */
data class ProfileHeaderCollapse(val distance: Float) {
    /** 0 at rest, 1 once folded. */
    fun progress(offset: Float): Float = if (distance <= 0f) 0f else (offset / distance).coerceIn(0f, 1f)

    /** Whether the page has started to pass under the folded header — when it needs a backdrop, and not before. */
    fun isContentUnder(offset: Float): Boolean = offset > distance

    /** Where a scroll that ends inside the fold comes to rest: folded or unfolded, the nearer, never halfway. */
    fun restingOffset(offset: Float): Float = when {
        offset <= 0f || offset >= distance -> offset
        offset < distance / 2 -> 0f
        else -> distance
    }

    /**
     * The fold while the pager moves between pages, each scrolled its own way: the fold of each page is
     * what is blended, not the offsets — halfway from a page scrolled far down to one at rest is half
     * folded.
     */
    fun progress(offsets: List<Float>, pagePosition: Float): Float = blend(offsets.map(::progress), pagePosition)

    /**
     * The empty room a page needs at its end so that it can always scroll the whole fold: a page shorter
     * than that would stop halfway, and rest half folded.
     */
    fun trailingRoom(contentHeight: Float, viewportHeight: Float): Float = (viewportHeight + distance - contentHeight).coerceAtLeast(0f)

    companion object {
        /**
         * One value per page, blended between the two pages the pager stands between: `values[0]` at 0,
         * `values[1]` at 1, and so on. A position past either end holds the end's value.
         */
        fun blend(values: List<Float>, pagePosition: Float): Float {
            if (values.isEmpty()) return 0f
            val position: Float = pagePosition.coerceIn(0f, values.lastIndex.toFloat())
            val lower: Int = floor(position).toInt()
            val upper: Int = minOf(lower + 1, values.lastIndex)
            return values[lower] + (values[upper] - values[lower]) * (position - lower)
        }
    }
}
