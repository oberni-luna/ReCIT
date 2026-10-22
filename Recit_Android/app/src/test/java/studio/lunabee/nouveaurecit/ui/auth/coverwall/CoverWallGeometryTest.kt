package studio.lunabee.nouveaurecit.ui.auth.coverwall

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CoverWallGeometryTest {
    private val sizes: List<Pair<Float, Float>> = listOf(320f to 568f, 393f to 852f, 412f to 915f, 800f to 1280f)
    private val instants: List<Float> = listOf(0f, 1.3f, 17f, 250f, 3_600f)

    @Test
    fun the_grid_tiles_the_container_at_every_instant() {
        for ((width, height) in sizes) {
            val geometry = CoverWallGeometry(width, height)
            for (column in 0 until geometry.columns) {
                for (time in instants) {
                    val tops: List<Float> = (0 until geometry.rowCount).map { geometry.y(it, column, time) }.sorted()
                    assertTrue("a cover covers the top edge", tops.first() <= 0f)
                    assertTrue("a cover reaches the bottom edge", tops.last() + geometry.coverHeight >= height)
                    tops.zipWithNext().forEach { (upper, lower) -> assertEquals(geometry.rowPitch, lower - upper, 0.01f) }
                }
            }
        }
    }

    @Test
    fun a_column_comes_back_to_where_it_started_after_one_period() {
        val geometry = CoverWallGeometry(393f, 852f)
        for (column in 0 until geometry.columns) {
            val period: Float = geometry.period / geometry.speed(column)
            assertEquals(geometry.y(0, column, 0f), geometry.y(0, column, period), 0.05f)
        }
    }

    @Test
    fun even_columns_drift_down_and_odd_ones_up() {
        val geometry = CoverWallGeometry(393f, 852f)
        assertEquals(1f, geometry.direction(0))
        assertEquals(-1f, geometry.direction(1))
        assertTrue(geometry.y(1, 0, 0.1f) > geometry.y(1, 0, 0f))
        assertTrue(geometry.y(1, 1, 0.1f) < geometry.y(1, 1, 0f))
    }

    @Test
    fun four_columns_with_gutters_fill_the_width() {
        val geometry = CoverWallGeometry(393f, 852f)
        val right: Float = geometry.x(geometry.columns - 1) + geometry.coverWidth + CoverWallGeometry.GUTTER
        assertEquals(393f, right, 0.01f)
        assertEquals(geometry.coverWidth * 3f / 2f, geometry.coverHeight, 0.01f)
    }

    @Test
    fun a_degenerate_container_draws_nothing() {
        assertEquals(0, CoverWallGeometry(0f, 852f).rowCount)
        assertEquals(0, CoverWallGeometry(393f, 0f).rowCount)
        assertNull(CoverWallGeometry(393f, 852f).imageIndex(0, 0, imageCount = 0))
    }
}
