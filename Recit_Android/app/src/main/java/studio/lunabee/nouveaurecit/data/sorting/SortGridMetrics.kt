package studio.lunabee.nouveaurecit.data.sorting

import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * `SortGridMetrics`: every measurement of the sorting surface, derived from the width it is given, in
 * dp as `Float` so it tests without Compose.
 *
 * Pure because this is where a visual rewrite breaks in silence: a card sized for one screen wraps to
 * two columns on a narrower one. The two column widths are the owner's formulas, read off the mockup
 * (`Nouveau récits`, `160:6659`):
 * - **Étagères**: three columns, 16 dp margins and gutters — `3W + 4×16 = width`.
 * - **Livres à ranger**: three columns *and a peek*, because the carousel scrolls horizontally and a row
 *   that ends flush at the edge looks finished — 16 dp margin, 12 dp gutters, 40 dp of the next card.
 *
 * Cover art reserves a **2:3 frame before its image exists**, so a pile does not re-lay itself out as
 * its images arrive.
 */
data class SortGridMetrics(val containerWidth: Float) {
    /** A width and a height, in dp. */
    data class CoverSize(val width: Float, val height: Float)

    /** A displacement from the front cover, in dp: positive x to the right, positive y downwards. */
    data class FanOffset(val x: Float, val y: Float)

    /** One étagère card's width on a grid of [columns]: `(width − (columns + 1) × 16) / columns`. */
    fun shelfColumnWidth(columns: Int): Float {
        val count: Float = max(1, columns).toFloat()
        val gaps: Float = (count + 1) * SHELF_SPACING
        return max(0f, (containerWidth - gaps) / count)
    }

    /** One étagère card's width on the full three-column grid. */
    val shelfColumnWidth: Float get() = shelfColumnWidth(COLUMN_COUNT)

    /**
     * One book card's width: one margin, three columns, **three** gutters — two between the visible
     * cards and one before the card that peeks — and the peek. `(width − 16 − 3 × 12 − 40) / 3`.
     */
    val bookColumnWidth: Float
        get() {
            val columns: Float = COLUMN_COUNT.toFloat()
            val taken: Float = SHELF_SPACING + BOOK_SPACING * columns + BOOK_PEEK
            return max(0f, (containerWidth - taken) / columns)
        }

    /** The height the carousel claims, so the anchored panel can reserve it before the library has loaded. */
    val carouselHeight: Float get() = CARD_HEIGHT

    companion object {
        /** The gutter and margin the étagère grid is laid out on. */
        const val SHELF_SPACING: Float = 16f

        /** The gutter between two book cards. */
        const val BOOK_SPACING: Float = 12f

        /** How much of the fourth book card shows past the third: the only thing that says "this scrolls". */
        const val BOOK_PEEK: Float = 40f

        /** How many columns the grid uses when the collection fills it. */
        const val COLUMN_COUNT: Int = 3

        /** Up to how many étagères the grid uses two columns rather than three. */
        const val NARROW_GRID_THRESHOLD: Int = 2

        /** A card's total height: the art, then one or two lines of title. */
        const val CARD_HEIGHT: Float = 158f

        /** The share of an étagère card's height its pile occupies, the rest being the title. */
        const val ART_HEIGHT: Float = 106f

        /** The same for a book card, whose title is taller (`160:6659`). */
        const val BOOK_ART_HEIGHT: Float = 100f

        /** A cover's reserved shape, before its image exists. */
        const val COVER_ASPECT_RATIO: Float = 2f / 3f

        /** How many covers a pile draws at most. */
        const val PILE_COVER_LIMIT: Int = 5

        /** How far apart two ranks of the fan sit, as a share of the card's width. */
        const val PILE_FAN_STEP: Float = 0.075f

        /** What share of that step is vertical. The fan opens sideways and leans *down* only. */
        const val PILE_FAN_VERTICAL_SHARE: Float = 0.5f

        /** A piled cover's width, as a share of the card's. */
        const val PILE_COVER_WIDTH_SHARE: Float = 0.46f

        /** The same for the one cover of an étagère holding a single book, drawn face-on. */
        const val SINGLE_COVER_WIDTH_SHARE: Float = 0.52f

        /**
         * How many columns to lay [shelfCount] étagères on. Two when there are two or fewer: three
         * narrow cards and empty slots read as a screen that failed to load. The « + » tile does not count.
         */
        fun columnCount(shelfCount: Int): Int = if (shelfCount <= NARROW_GRID_THRESHOLD) 2 else COLUMN_COUNT

        /** A cover drawn [width] wide, in its reserved 2:3 frame. */
        fun coverSize(width: Float): CoverSize = CoverSize(width, width / COVER_ASPECT_RATIO)

        // The pile's geometry. A pile is not just its front cover: the ranks behind it step downwards,
        // and every cover leans. Sized on the front cover alone, a full fan on a two-column grid ran past
        // the art band and painted over the card's title; these functions keep it inside.

        /** How far the deepest rank of a full fan sits below the front cover. Ranks pair up, one each side. */
        fun pileFanDrop(width: Float): Float {
            val deepestRank: Float = (PILE_COVER_LIMIT / 2).toFloat()
            return deepestRank * width * PILE_FAN_STEP * PILE_FAN_VERTICAL_SHARE
        }

        /** How far up the whole fan is drawn — half the drop — so it is centred in the art band. */
        fun pileVerticalInset(width: Float): Float = pileFanDrop(width) / 2

        /**
         * One cover's frame on a card [width] wide, clamped so the fan — its drop and its lean included —
         * stays inside [ART_HEIGHT]. A cover leaning by θ claims `w·sin θ + h·cos θ` of height, so the
         * tallest that fits is `(artHeight − drop − w·sin θ) / cos θ`; below it the book keeps its 2:3.
         */
        fun pileCoverSize(width: Float, isSingleCover: Boolean): CoverSize {
            val coverWidth: Float = width * if (isSingleCover) SINGLE_COVER_WIDTH_SHARE else PILE_COVER_WIDTH_SHARE
            // One cover fans nowhere, but it leans like any other.
            val drop: Float = if (isSingleCover) 0f else pileFanDrop(width)
            val tilt: Float = Math.toRadians(SortPile.TILT_AMPLITUDE).toFloat()
            val leanWidth: Float = coverWidth * sin(tilt)
            val available: Float = max(0f, ART_HEIGHT - drop - leanWidth)
            return CoverSize(coverWidth, min(coverWidth / COVER_ASPECT_RATIO, available / cos(tilt)))
        }

        /**
         * Where the cover at [depth] sits relative to the front one, on a card [width] wide. The fan opens
         * **alternately** — one cover right, the next left, then further right, further left — so the pile
         * stays centred on the book a drag will take. The front cover (depth 0) does not move; a single
         * cover is depth 0 and therefore never fans.
         */
        fun fanOffset(depth: Int, width: Float): FanOffset {
            if (depth <= 0) return FanOffset(0f, 0f)
            val step: Float = width * PILE_FAN_STEP
            val rank: Float = ((depth + 1) / 2).toFloat()
            val side: Float = if (depth % 2 == 0) -1f else 1f
            return FanOffset(x = side * rank * step, y = rank * step * PILE_FAN_VERTICAL_SHARE)
        }
    }
}
