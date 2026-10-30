package studio.lunabee.nouveaurecit.data.lists

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.min

/**
 * `Model/CoverFlow/CoverFlowGeometry.swift`: how each cover of a list's cover flow is turned, pushed
 * aside, shrunk and shaded, given how far its centre sits from the centre of the strip.
 *
 * The strip's items sit one [STEP] apart, so a swipe moves by whole covers; what the eye sees is
 * another distance, [PITCH], the overlap of two turned covers — drawn at the step, a finger moving
 * 38 dp went one book further. Each cover is drawn back from where the strip lays it to where the
 * pitch puts it, and [push] clears the cover in front.
 *
 * Everything grows over the first step and saturates after it, so a swipe reads as one movement;
 * only the shade keeps deepening with the rank. Distances are in dp.
 */
data class CoverFlowGeometry(
    /** The width of the cover facing the reader. */
    val coverWidth: Float,
) {
    /**
     * What a cover's angle, offset, scale and shade are for one distance. [angle] is positive on the
     * left of the strip and negative on its right, so a turned cover's inner edge recedes towards the
     * cover in front.
     */
    data class Placement(val angle: Float, val offset: Float, val scale: Float, val shade: Float)

    /** How much wider a turned cover looks than nothing: its width, shrunk, seen at its angle. */
    val turnedWidth: Float get() = coverWidth * TURNED_SCALE * cos(MAX_ANGLE * PI.toFloat() / 180)

    /** Where the first neighbour has to sit — half the front cover, the gap, half a turned cover — minus where the strip puts it. */
    val push: Float get() = coverWidth / 2 + GAP_TO_FRONT + turnedWidth / 2 - PITCH

    /** The placement of a cover whose centre is [distance] dp from the strip's centre, negative on the left. */
    fun placement(distance: Float): Placement {
        val rank: Float = distance / STEP
        val turn: Float = min(abs(rank), 1f)
        val side: Float = if (rank < 0) -1f else 1f
        return Placement(
            angle = -side * turn * MAX_ANGLE,
            // Back from the step to the pitch, then aside to clear the front cover.
            offset = rank * (PITCH - STEP) + side * turn * push,
            scale = 1 - (1 - TURNED_SCALE) * turn,
            shade = SHADE_PER_RANK * min(abs(rank), MAX_SHADED_RANK),
        )
    }

    companion object {
        /** The distance between two neighbours as they are drawn. */
        const val PITCH: Float = 38f

        /** The distance between two neighbours as the strip lays them out: how far the finger travels per book. */
        const val STEP: Float = 64f

        /** The gap between the cover in front and the turned edge of its neighbour. */
        const val GAP_TO_FRONT: Float = 14f

        const val MAX_ANGLE: Float = 55f

        const val TURNED_SCALE: Float = 0.9f

        const val SHADE_PER_RANK: Float = 0.04f

        const val MAX_SHADED_RANK: Float = 4f
    }
}
