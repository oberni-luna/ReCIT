package studio.lunabee.nouveaurecit.ui.inventory

import kotlin.math.floor
import studio.lunabee.nouveaurecit.data.db.ItemRow

/**
 * `ShelfCardMetrics` and `ShelfDrawnBooks`, in plain numbers (dp as `Float`) so they test without
 * Compose: a card's book zone, its plank, the room above, and which copies stand on it.
 *
 * The iOS card paints spines; this port stands the first covers on the plank instead, so the
 * cover geometry ([coverHeight], [coverWidth], [fittingCount]) is this port's own.
 */
data class ShelfCardMetrics(val width: Float) {
    val plankHeight: Float get() = width * 129f / 820f
    val booksWidth: Float get() = (width - HORIZONTAL_MARGIN * 2).coerceAtLeast(0f)

    /** Four covers stand side by side on a phone-sized card. */
    val coverHeight: Float get() = width * 9f / 32f

    /** The covers and a little headroom — no more, so the plank does not float under empty space. */
    val zoneHeight: Float get() = coverHeight + HEADROOM
    val topRoom: Float get() = TOP_ROOM
    val coverWidth: Float get() = coverHeight * 2f / 3f

    /** How many covers stand side by side in [booksWidth], [COVER_GAP] apart. */
    val fittingCount: Int
        get() = if (coverWidth <= 0f) 0 else floor((booksWidth + COVER_GAP) / (coverWidth + COVER_GAP)).toInt().coerceAtLeast(0)

    companion object {
        const val HORIZONTAL_MARGIN: Float = 24f
        const val COVER_GAP: Float = 4f
        const val CARD_WIDTH_FRACTION: Float = 0.86f
        const val GUTTER: Float = 14f
        const val SIDE_PADDING: Float = 12f
        const val LABEL_OVERLAP: Float = 14f
        const val HEADROOM: Float = 12f
        const val TOP_ROOM: Float = 8f
    }
}

object ShelfDrawnBooks {
    const val LIMIT: Int = 20

    /** Copies with a cover first, newest first within each group, at most [limit]. */
    fun from(items: List<ItemRow>, limit: Int = LIMIT): List<ItemRow> =
        items
            .sortedWith(compareByDescending<ItemRow> { !it.image.isNullOrEmpty() }.thenByDescending { it.item.created })
            .take(limit)
}
