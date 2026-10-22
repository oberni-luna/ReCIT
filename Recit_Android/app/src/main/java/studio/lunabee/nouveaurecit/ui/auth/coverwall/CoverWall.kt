package studio.lunabee.nouveaurecit.ui.auth.coverwall

import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableFloatState
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import coil3.compose.AsyncImage
import kotlinx.coroutines.isActive
import studio.lunabee.nouveaurecit.designsystem.Primitive
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.network.ApiService

/**
 * `CoverWallView`: four columns of covers drifting slowly, read on a clock rather than animated —
 * each frame asks [CoverWallGeometry] where the covers are now, so pausing freezes the wall where
 * it stands. The drift stops when the system's animations are off or the screen is not started.
 *
 * Until covers arrive — and for good if inventaire.io never answers — every slot is a painted
 * jacket in the brand's tints, so the wall has no empty state. The wall takes no touch and says
 * nothing to TalkBack.
 */
@Composable
fun CoverWall(paths: List<String>, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val elapsed: MutableFloatState = remember { mutableFloatStateOf(0f) }
    val animates: Boolean = remember {
        Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f
    }

    LaunchedEffect(animates) {
        if (!animates) return@LaunchedEffect
        lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            var last: Long = -1L
            while (isActive) {
                withFrameNanos { now ->
                    if (last >= 0L) elapsed.floatValue += (now - last) / 1_000_000_000f
                    last = now
                }
            }
        }
    }

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(Primitive.Green900)
            .clearAndSetSemantics {},
    ) {
        val geometry = CoverWallGeometry(maxWidth.value, maxHeight.value)
        val density: Density = LocalDensity.current
        val widthPx: Float = with(density) { geometry.coverWidth.dp.toPx() }
        val heightPx: Float = with(density) { geometry.coverHeight.dp.toPx() }
        for (column in 0 until geometry.columns) {
            for (row in 0 until geometry.rowCount) {
                val index: Int? = geometry.imageIndex(row, column, paths.size)
                CoverSlot(
                    url = index?.let { CoverWallCatalog.url(ApiService.BASE_URL, paths[it], widthPx, heightPx) },
                    painted = PAINTED[geometry.paintedIndex(row, column, PAINTED.size)],
                    modifier = Modifier
                        .offset(x = geometry.x(column).dp)
                        .size(width = geometry.coverWidth.dp, height = geometry.coverHeight.dp)
                        .graphicsLayer { translationY = geometry.y(row, column, elapsed.floatValue).dp.toPx() },
                )
            }
        }
    }
}

/** One case of the wall: the painted jacket, the real cover over it once it loads. */
@Composable
private fun CoverSlot(url: String?, painted: PaintedJacket, modifier: Modifier) {
    Box(modifier.clip(RoundedCornerShape(3.dp)).background(painted.cloth)) {
        Column(Modifier.fillMaxSize()) {
            Spacer(Modifier.fillMaxHeight(0.18f))
            Box(Modifier.fillMaxWidth().height(14.dp).background(painted.band))
            Spacer(Modifier.height(10.dp))
            Box(Modifier.padding(horizontal = 10.dp).fillMaxWidth(0.7f).height(5.dp).background(painted.ink.copy(alpha = 0.55f)))
            Spacer(Modifier.height(6.dp))
            Box(Modifier.padding(horizontal = 10.dp).fillMaxWidth(0.45f).height(5.dp).background(painted.ink.copy(alpha = 0.4f)))
        }
        if (url != null) {
            AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        }
    }
}

/** `PaintedCoverView`'s palette: flat jackets in the brand's own tints, never a publisher's art. */
private data class PaintedJacket(val cloth: Color, val band: Color, val ink: Color)

private val PAINTED: List<PaintedJacket> = listOf(
    PaintedJacket(Primitive.Green800, Primitive.Green400, Primitive.Green100),
    PaintedJacket(ShelfPalette.Parchment, Primitive.Green700, Primitive.Gray900),
    PaintedJacket(Primitive.Green700, Primitive.Yellow300, Primitive.Green100),
    PaintedJacket(Primitive.Red800, Primitive.Red100, Primitive.Red100),
    PaintedJacket(Primitive.Yellow400, Primitive.Green800, Primitive.Gray900),
    PaintedJacket(Primitive.Green600, Primitive.Green200, Primitive.Green900),
)
