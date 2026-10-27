package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size

/**
 * iOS `CoverZoom`: how far a cover shown full screen is magnified, and where it has been dragged to.
 *
 * A [scale] of 1 is the cover fitted to the screen. [fillScale] is the scale at which it fills the
 * screen instead — known only once the cover has been laid out, through [measure].
 *
 * A gesture in flight is applied on top of what the previous gestures left ([pinching], [panning]),
 * and folded into it when the fingers lift ([endPinch], [endPan]). The scale never leaves
 * `1..maxScale`, and a cover back at its fitted size is centred again: an offset only means
 * something while the cover is larger than the screen.
 */
data class CoverZoom(
    val scale: Float = 1f,
    val offset: Offset = Offset.Zero,
    val fillScale: Float = 1f,
) {
    /**
     * From fitted to whichever is larger: four times that, or filled — a cover much narrower than
     * the screen must still be able to fill it.
     */
    val maxScale: Float get() = maxOf(MAXIMUM_PINCH_SCALE, fillScale)

    val isZoomed: Boolean get() = scale > 1f

    /**
     * Records the cover's size once fitted to [screen], which gives the scale that fills it. A
     * cover with the screen's own proportions fills it at its fitted size; an unmeasured one keeps
     * the fill scale it had.
     */
    fun measure(fitted: Size, screen: Size): CoverZoom {
        if (fitted.width <= 0f || fitted.height <= 0f) return this
        return copy(fillScale = maxOf(1f, screen.width / fitted.width, screen.height / fitted.height))
    }

    fun pinching(by: Float): CoverZoom {
        val zoom: CoverZoom = copy(scale = (scale * by).coerceIn(1f, maxScale))
        return if (zoom.isZoomed) zoom else zoom.copy(offset = Offset.Zero)
    }

    fun endPinch(by: Float): CoverZoom = pinching(by)

    /** A fitted cover does not move: dragging it is the swipe that closes the screen. */
    fun panning(by: Offset): CoverZoom = if (isZoomed) copy(offset = offset + by) else this

    fun endPan(by: Offset): CoverZoom = panning(by)

    /**
     * A double tap fills the screen with a fitted cover, and fits anything else back to it — a
     * filled cover as well as one pinched or dragged anywhere in between.
     */
    fun toggle(): CoverZoom = copy(scale = if (isZoomed) 1f else fillScale, offset = Offset.Zero)

    companion object {
        /** How far a pinch may go past the fitted size, whatever the cover's proportions. */
        const val MAXIMUM_PINCH_SCALE: Float = 4f

        /** The share of the screen's height a fitted cover is swiped down by to close it. */
        const val CLOSING_SWIPE_FRACTION: Float = 0.15f

        /** Whether a fitted cover swiped down by [drag] closes the screen when released. */
        fun closesOnRelease(drag: Float, screenHeight: Float): Boolean =
            screenHeight > 0f && drag > screenHeight * CLOSING_SWIPE_FRACTION
    }
}
