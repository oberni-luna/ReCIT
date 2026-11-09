package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp

/**
 * One row of an inset-grouped section (feature 0039): the cell colour, inset by the screen's margin,
 * rounded at the section's two ends — so the section reads as one card on the list's background.
 */
fun Modifier.groupedCell(index: Int, count: Int, color: Color): Modifier {
    val radius: Dp = CornerRadius.rounded
    val shape = RoundedCornerShape(
        topStart = if (index == 0) radius else CornerRadius.none,
        topEnd = if (index == 0) radius else CornerRadius.none,
        bottomStart = if (index == count - 1) radius else CornerRadius.none,
        bottomEnd = if (index == count - 1) radius else CornerRadius.none,
    )
    return padding(horizontal = Spacing.medium).clip(shape).background(color)
}
