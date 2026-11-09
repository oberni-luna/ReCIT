package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.MotionDurationScale
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.withContext
import studio.lunabee.nouveaurecit.designsystem.RecitTheme

/**
 * `ListCoverHalo`: the ring around the cover a list arrives on from a book screen — a tinted line close to
 * the cover's edge, a faint wide one further out, both fading to nothing as soon as they appear. It follows
 * the cover's corners, a disc for an author ([cornerRadius] half the width).
 *
 * Drawn over the cover's bounds, outside them: its parent must not clip. The fade plays with the system's
 * animations off too — only the scroll gives way to them.
 */
@Composable
internal fun ListCoverHalo(cornerRadius: Dp, modifier: Modifier = Modifier) {
    val opacity: Animatable<Float, *> = remember { Animatable(1f) }
    val color: Color = RecitTheme.colors.foregroundTinted
    LaunchedEffect(Unit) {
        withContext(FullSpeed) {
            opacity.animateTo(0f, tween(durationMillis = HALO_FADE_MILLIS, easing = LinearOutSlowInEasing))
        }
    }
    Canvas(modifier) {
        val alpha: Float = opacity.value
        outline(GlowOffset, GlowWidth, cornerRadius, color.copy(alpha = GLOW_OPACITY * alpha))
        outline(RingOffset, RingWidth, cornerRadius, color.copy(alpha = alpha))
    }
}

/** How long the halo takes to fade, after which the arrival is over. */
internal const val HALO_FADE_MILLIS: Int = 1_200

private fun DrawScope.outline(offset: Dp, width: Dp, cornerRadius: Dp, color: Color) {
    val outset: Float = offset.toPx()
    val radius: Float = (cornerRadius + offset).toPx()
    drawRoundRect(
        color = color,
        topLeft = Offset(-outset, -outset),
        size = Size(size.width + 2 * outset, size.height + 2 * outset),
        cornerRadius = CornerRadius(radius, radius),
        style = Stroke(width = width.toPx()),
    )
}

/** A clock that ignores the animator duration scale, so the fade still plays under « Supprimer les animations ». */
private object FullSpeed : MotionDurationScale {
    override val scaleFactor: Float = 1f
}

// Figma `944:8280`: neither offset is a spacing token.
private val RingOffset: Dp = 5.dp
private val RingWidth: Dp = 2.dp
private val GlowOffset: Dp = 11.dp
private val GlowWidth: Dp = 8.dp
private const val GLOW_OPACITY: Float = 0.14f
