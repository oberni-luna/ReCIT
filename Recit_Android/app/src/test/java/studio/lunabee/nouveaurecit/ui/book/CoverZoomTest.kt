package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/*
 * iOS `CoverZoomTests`. A cover shown full screen can be pinched, dragged and double-tapped. What
 * can be got wrong is the arithmetic between gestures: a scale that escapes its bounds, a pinch
 * that forgets the one before it, a cover left off-centre once it is back at its fitted size.
 */
class CoverZoomTest {
    /** A cover fitted to 400 × 600 on a 400 × 900 screen touches its sides, and fills its height at ×1.5. */
    private val fitted: Size = Size(400f, 600f)
    private val screen: Size = Size(400f, 900f)

    @Test
    fun startsFittedAndCentred() {
        val zoom: CoverZoom = CoverZoom()

        assertEquals(1f, zoom.scale)
        assertEquals(Offset.Zero, zoom.offset)
        assertFalse(zoom.isZoomed)
    }

    @Test
    fun aPinchBuildsOnTheOneBefore() {
        val zoom: CoverZoom = CoverZoom().endPinch(2f).endPinch(1.5f)

        assertEquals(3f, zoom.scale)
    }

    @Test
    fun theScaleStaysWithinItsRange() {
        assertEquals(1f, CoverZoom().pinching(0.2f).scale)
        assertEquals(CoverZoom.MAXIMUM_PINCH_SCALE, CoverZoom().endPinch(10f).scale)
    }

    @Test
    fun fillsAtTheLargerOfTheTwoRatios() {
        assertEquals(1.5f, CoverZoom().measure(fitted, screen).fillScale)
    }

    @Test
    fun aCoverWithTheScreensProportionsFillsWhenFitted() {
        assertEquals(1f, CoverZoom().measure(screen, screen).fillScale)
    }

    @Test
    fun anUnmeasuredCoverKeepsItsFillScale() {
        val zoom: CoverZoom = CoverZoom().measure(fitted, screen).measure(Size.Zero, screen)

        assertEquals(1.5f, zoom.fillScale)
    }

    /** A very narrow cover must still be able to fill the screen, even past the pinch limit. */
    @Test
    fun aPinchCanReachTheFillScale() {
        val zoom: CoverZoom = CoverZoom().measure(Size(80f, 900f), screen).endPinch(10f)

        assertEquals(5f, zoom.scale)
    }

    @Test
    fun aFittedCoverDoesNotMove() {
        assertEquals(Offset.Zero, CoverZoom().panning(Offset(40f, 80f)).offset)
    }

    @Test
    fun aMagnifiedCoverMovesByEachDrag() {
        val zoom: CoverZoom = CoverZoom().endPinch(2f).endPan(Offset(10f, -20f)).endPan(Offset(5f, 5f))

        assertEquals(Offset(15f, -15f), zoom.offset)
    }

    @Test
    fun pinchingBackToFitRecentres() {
        val zoom: CoverZoom = CoverZoom().endPinch(2f).endPan(Offset(30f, 30f)).endPinch(0.4f)

        assertFalse(zoom.isZoomed)
        assertEquals(Offset.Zero, zoom.offset)
    }

    @Test
    fun aDoubleTapFillsAFittedCover() {
        val zoom: CoverZoom = CoverZoom().measure(fitted, screen).toggle()

        assertEquals(1.5f, zoom.scale)
        assertEquals(Offset.Zero, zoom.offset)
    }

    @Test
    fun aDoubleTapFitsAFilledCover() {
        val zoom: CoverZoom = CoverZoom().measure(fitted, screen).toggle().toggle()

        assertEquals(1f, zoom.scale)
    }

    @Test
    fun aDoubleTapFitsACoverZoomedAnywhereElse() {
        val zoom: CoverZoom = CoverZoom().measure(fitted, screen).endPinch(3f).endPan(Offset(12f, 0f)).toggle()

        assertEquals(1f, zoom.scale)
        assertEquals(Offset.Zero, zoom.offset)
    }

    /** A cover already filling the screen when fitted has nothing to grow to: a double tap leaves it fitted. */
    @Test
    fun aDoubleTapOnACoverThatAlreadyFillsLeavesItFitted() {
        val zoom: CoverZoom = CoverZoom().measure(screen, screen).toggle()

        assertFalse(zoom.isZoomed)
    }

    @Test
    fun aLongEnoughSwipeDownCloses() {
        assertTrue(CoverZoom.closesOnRelease(drag = 200f, screenHeight = 900f))
        assertFalse(CoverZoom.closesOnRelease(drag = 100f, screenHeight = 900f))
        assertFalse(CoverZoom.closesOnRelease(drag = -400f, screenHeight = 900f))
        assertFalse(CoverZoom.closesOnRelease(drag = 200f, screenHeight = 0f))
    }
}
