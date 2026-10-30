package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Test

/** `CoverFlowGeometryTests`. */
class CoverFlowGeometryTest {
    private val geometry: CoverFlowGeometry = CoverFlowGeometry(coverWidth = 160f)

    @Test
    fun the_cover_in_front_faces_the_reader() {
        val front: CoverFlowGeometry.Placement = geometry.placement(0f)
        assertEquals(0f, front.angle, 0.001f)
        assertEquals(0f, front.offset, 0.001f)
        assertEquals(1f, front.scale, 0.001f)
        assertEquals(0f, front.shade, 0.001f)
    }

    @Test
    fun a_neighbour_is_turned_away_drawn_at_the_pitch_and_pushed_clear() {
        val right: CoverFlowGeometry.Placement = geometry.placement(CoverFlowGeometry.STEP)
        assertEquals(-55f, right.angle, 0.001f)
        assertEquals(0.9f, right.scale, 0.001f)
        assertEquals(CoverFlowGeometry.PITCH - CoverFlowGeometry.STEP + geometry.push, right.offset, 0.001f)
        val left: CoverFlowGeometry.Placement = geometry.placement(-CoverFlowGeometry.STEP)
        assertEquals(55f, left.angle, 0.001f)
        assertEquals(-right.offset, left.offset, 0.001f)
    }

    @Test
    fun half_way_is_half_turned() {
        assertEquals(-27.5f, geometry.placement(CoverFlowGeometry.STEP / 2).angle, 0.001f)
    }

    @Test
    fun only_the_shade_keeps_deepening_and_stops_at_the_fourth_rank() {
        val third: CoverFlowGeometry.Placement = geometry.placement(3 * CoverFlowGeometry.STEP)
        assertEquals(-55f, third.angle, 0.001f)
        assertEquals(0.12f, third.shade, 0.001f)
        assertEquals(0.16f, geometry.placement(9 * CoverFlowGeometry.STEP).shade, 0.001f)
    }

    @Test
    fun the_rest_of_the_row_keeps_the_pitch() {
        val second: Float = geometry.placement(2 * CoverFlowGeometry.STEP).offset + 2 * CoverFlowGeometry.STEP
        val third: Float = geometry.placement(3 * CoverFlowGeometry.STEP).offset + 3 * CoverFlowGeometry.STEP
        assertEquals(CoverFlowGeometry.PITCH, third - second, 0.001f)
    }
}
