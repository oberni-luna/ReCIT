package studio.lunabee.nouveaurecit.ui.auth.coverwall

import kotlin.math.ceil
import kotlin.math.max

/**
 * `Model/CoverWall/CoverWallGeometry.swift`, in dp as `Float`: for a size, a column count and an
 * instant, where each cover of the welcome wall is. Columns drift at their own speed and phase,
 * even ones down, odd ones up; the grid tiles the container at every instant and the offset loops
 * over [period] without a jump.
 */
data class CoverWallGeometry(val width: Float, val height: Float, val columnCount: Int = DEFAULT_COLUMN_COUNT) {
    val columns: Int = max(1, columnCount)
    val coverWidth: Float = max(0f, (max(0f, width) - (columns + 1) * GUTTER) / columns)
    val coverHeight: Float = coverWidth / COVER_ASPECT_RATIO
    val rowPitch: Float = coverHeight + GUTTER
    val rowCount: Int = if (coverWidth > 0f && height > 0f) ceil(height / rowPitch).toInt() + OVERDRAW else 0
    val period: Float = rowCount * rowPitch

    fun x(column: Int): Float = GUTTER + column * (coverWidth + GUTTER)

    fun direction(column: Int): Float = if (column % 2 == 0) 1f else -1f

    fun speed(column: Int): Float = COLUMN_SPEEDS[column % COLUMN_SPEEDS.size]

    fun phase(column: Int): Float = COLUMN_PHASES[column % COLUMN_PHASES.size] * rowPitch

    /** The top of [row] in [column] after [elapsedSeconds], wrapped into `[-rowPitch, period - rowPitch)`. */
    fun y(row: Int, column: Int, elapsedSeconds: Float): Float {
        if (rowCount == 0) return 0f
        val travelled: Float = direction(column) * speed(column) * elapsedSeconds
        val raw: Float = row * rowPitch + travelled + phase(column)
        val remainder: Float = (raw + rowPitch) % period
        val positive: Float = if (remainder < 0f) remainder + period else remainder
        return positive - rowPitch
    }

    fun imageIndex(row: Int, column: Int, imageCount: Int): Int? =
        if (imageCount <= 0) null else slot(row, column) % imageCount

    fun paintedIndex(row: Int, column: Int, variantCount: Int): Int =
        if (variantCount <= 0) 0 else slot(row, column) % variantCount

    private fun slot(row: Int, column: Int): Int = max(0, row) * columns + max(0, column)

    companion object {
        const val DEFAULT_COLUMN_COUNT: Int = 4
        const val GUTTER: Float = 8f
        const val COVER_ASPECT_RATIO: Float = 2f / 3f
        const val OVERDRAW: Int = 2
        val COLUMN_SPEEDS: List<Float> = listOf(12f, 15f, 10.5f, 13.5f)
        val COLUMN_PHASES: List<Float> = listOf(0f, 0.41f, 0.17f, 0.68f)
    }
}
