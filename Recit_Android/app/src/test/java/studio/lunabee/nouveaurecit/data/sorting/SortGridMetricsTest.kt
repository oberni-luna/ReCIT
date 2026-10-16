package studio.lunabee.nouveaurecit.data.sorting

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

/**
 * `SortGridMetricsTests`: the sorting surface's measurements at the widths phones actually have. Three
 * columns must stay three columns: a card sized for one screen wraps on a narrower one, and nobody
 * notices until a small phone turns up.
 */
class SortGridMetricsTest {
    /** The iOS suite's four widths (SE, mini, 17, Pro Max) — and the common Android 360 and 411 dp. */
    private val widths: List<Float> = listOf(320f, 360f, 375f, 393f, 411f, 430f)

    private val tilt: Float = Math.toRadians(SortPile.TILT_AMPLITUDE).toFloat()

    private fun assertClose(expected: Float, actual: Float, tolerance: Float = 0.01f) {
        assertTrue("expected $expected, got $actual", abs(expected - actual) < tolerance)
    }

    // Étagères

    /** The owner's formula: `3W + 4 × 16 = width`. */
    @Test
    fun theShelfGridFillsItsWidthExactly() {
        for (width in widths) {
            val metrics: SortGridMetrics = SortGridMetrics(width)
            assertClose(width, metrics.shelfColumnWidth * 3 + SortGridMetrics.SHELF_SPACING * 4)
        }
    }

    @Test
    fun theShelfColumnMatchesTheMockupOnAThreeNinetyThreeScreen() {
        assertClose(109.666f, SortGridMetrics(393f).shelfColumnWidth)
    }

    /** A small collection gets two columns: three narrow cards and empty slots read as a failed load. */
    @Test
    fun aSmallCollectionUsesTwoColumns() {
        for (shelfCount in listOf(0, 1, 2)) assertEquals(2, SortGridMetrics.columnCount(shelfCount))
    }

    @Test
    fun aFullCollectionUsesThreeColumns() {
        for (shelfCount in listOf(3, 4, 12, 40)) assertEquals(3, SortGridMetrics.columnCount(shelfCount))
    }

    /** Whatever the column count, the row fills its width exactly. */
    @Test
    fun everyColumnCountFillsTheWidth() {
        for (columns in listOf(2, 3)) {
            for (width in widths) {
                val card: Float = SortGridMetrics(width).shelfColumnWidth(columns)
                assertClose(width, card * columns + SortGridMetrics.SHELF_SPACING * (columns + 1))
            }
        }
    }

    @Test
    fun twoColumnsAreWiderThanThree() {
        val metrics: SortGridMetrics = SortGridMetrics(393f)

        assertTrue(metrics.shelfColumnWidth(2) > metrics.shelfColumnWidth(3))
    }

    // Livres à ranger

    /** Three cards, three gutters, one margin, and 40 dp of the fourth card showing. */
    @Test
    fun theCarouselLeavesRoomForAPeek() {
        for (width in widths) {
            val metrics: SortGridMetrics = SortGridMetrics(width)
            val laidOut: Float = SortGridMetrics.SHELF_SPACING + metrics.bookColumnWidth * 3 + SortGridMetrics.BOOK_SPACING * 3
            assertTrue(width - laidOut > SortGridMetrics.BOOK_PEEK - 0.01f)
        }
    }

    @Test
    fun theBookColumnMatchesTheMockupOnAThreeNinetyThreeScreen() {
        assertClose(100.333f, SortGridMetrics(393f).bookColumnWidth)
    }

    // Both

    @Test
    fun aBookCardIsNarrowerThanAnEtagereCard() {
        for (width in widths) {
            val metrics: SortGridMetrics = SortGridMetrics(width)
            assertTrue(metrics.bookColumnWidth < metrics.shelfColumnWidth)
        }
    }

    @Test
    fun everyColumnStaysPositiveAtEveryWidth() {
        for (width in widths) {
            val metrics: SortGridMetrics = SortGridMetrics(width)
            assertTrue(metrics.shelfColumnWidth > 0f)
            assertTrue(metrics.bookColumnWidth > 0f)
        }
    }

    /** A width smaller than its margins yields zero rather than a negative frame. */
    @Test
    fun anAbsurdWidthYieldsNoNegativeColumn() {
        val metrics: SortGridMetrics = SortGridMetrics(8f)

        assertEquals(0f, metrics.shelfColumnWidth)
        assertEquals(0f, metrics.bookColumnWidth)
    }

    // Covers

    @Test
    fun aCoverReservesATwoToThreeFrame() {
        assertClose(90f, SortGridMetrics.coverSize(60f).height)
    }

    // The pile inside its band

    /** On the two-column grid a fan of five ran past the art band; checked at every width, both column counts. */
    @Test
    fun aFullFanStaysInsideTheArtBand() {
        for (width in widths) {
            val metrics: SortGridMetrics = SortGridMetrics(width)
            for (columns in listOf(2, SortGridMetrics.COLUMN_COUNT)) {
                val cardWidth: Float = metrics.shelfColumnWidth(columns)
                val cover: SortGridMetrics.CoverSize = SortGridMetrics.pileCoverSize(cardWidth, isSingleCover = false)
                val leaning: Float = cover.width * sin(tilt) + cover.height * cos(tilt)
                val claimed: Float = SortGridMetrics.pileFanDrop(cardWidth) + leaning
                assertTrue("$width / $columns columns: $claimed", claimed <= SortGridMetrics.ART_HEIGHT + 0.01f)
            }
        }
    }

    /** The single cover has no fan to make room for, so it may be taller than a piled one — and still fits. */
    @Test
    fun aLoneCoverFitsAndIsTallerThanAPiledOne() {
        for (width in widths) {
            val cardWidth: Float = SortGridMetrics(width).shelfColumnWidth(2)
            val lone: SortGridMetrics.CoverSize = SortGridMetrics.pileCoverSize(cardWidth, isSingleCover = true)
            val piled: SortGridMetrics.CoverSize = SortGridMetrics.pileCoverSize(cardWidth, isSingleCover = false)

            assertTrue(lone.width * sin(tilt) + lone.height * cos(tilt) <= SortGridMetrics.ART_HEIGHT + 0.01f)
            assertTrue(lone.height > piled.height)
        }
    }

    /** A cover small enough to fit keeps its 2:3 shape: the clamp squashes only the piles that would overflow. */
    @Test
    fun aCoverThatFitsKeepsItsTwoToThreeShape() {
        val cover: SortGridMetrics.CoverSize = SortGridMetrics.pileCoverSize(60f, isSingleCover = false)

        assertClose(cover.width / SortGridMetrics.COVER_ASPECT_RATIO, cover.height)
    }

    /** Half the drop, so the fan reaches as far above the front cover as below it. */
    @Test
    fun theFanIsLiftedByHalfItsDrop() {
        val inset: Float = SortGridMetrics.pileVerticalInset(172.5f)

        assertClose(SortGridMetrics.pileFanDrop(172.5f) / 2, inset)
        assertTrue(inset > 0f)
    }

    // The fan's offsets (computed in `SortPileView` on iOS, lifted here so the view need not)

    /** The front cover stays put; the fan opens right, left, further right, further left, and only downwards. */
    @Test
    fun theFanOpensAlternatelyAndDownwards() {
        val width: Float = 100f
        val step: Float = width * SortGridMetrics.PILE_FAN_STEP
        val offsets: List<SortGridMetrics.FanOffset> = (0..4).map { SortGridMetrics.fanOffset(it, width) }

        assertEquals(SortGridMetrics.FanOffset(0f, 0f), offsets[0])
        assertClose(step, offsets[1].x)
        assertClose(-step, offsets[2].x)
        assertClose(2 * step, offsets[3].x)
        assertClose(-2 * step, offsets[4].x)
        assertClose(step / 2, offsets[1].y)
        assertClose(step / 2, offsets[2].y)
        assertClose(step, offsets[3].y)
        // The deepest rank sits exactly as far down as the drop the cover size was clamped for.
        assertClose(SortGridMetrics.pileFanDrop(width), offsets[4].y)
    }
}
