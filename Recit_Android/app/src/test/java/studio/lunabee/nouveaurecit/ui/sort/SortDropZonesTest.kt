package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SortDropZonesTest {
    private val card: SortDropZone<String> = SortDropZone("card", Rect(left = 16f, top = 100f, right = 116f, bottom = 258f))
    private val tile: SortDropZone<String> = SortDropZone("tile", Rect(left = 132f, top = 100f, right = 232f, bottom = 258f))
    private val panel: SortDropZone<String> = SortDropZone(
        "panel",
        Rect(left = 0f, top = 220f, right = 400f, bottom = 500f),
        layer = SortDropZone.PANEL_LAYER,
    )

    @Test
    fun theDropGoesToTheTargetUnderTheFinger() {
        assertEquals("card", SortDropZones.hit(listOf(card, tile, panel), Offset(50f, 150f)))
        assertEquals("tile", SortDropZones.hit(listOf(card, tile, panel), Offset(200f, 150f)))
    }

    @Test
    fun aDropBetweenTargetsGoesNowhere() {
        assertNull(SortDropZones.hit(listOf(card, tile, panel), Offset(124f, 150f)))
    }

    @Test
    fun thePanelWinsOverACardScrolledUnderneathIt() {
        assertEquals("panel", SortDropZones.hit(listOf(card, tile, panel), Offset(50f, 240f)))
    }

    @Test
    fun aTargetScrolledOutOfSightCatchesNothing() {
        val hidden: SortDropZone<String> = SortDropZone("hidden", Rect.Zero)
        assertNull(SortDropZones.hit(listOf(hidden), Offset.Zero))
    }
}
