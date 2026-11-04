package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.statusBars
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.RecitTypography
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize

/**
 * `UserProfileStickyHeader.Metrics`: what the fold of a reader's profile header is made of, known before
 * it happens — the picture's shrink, the rise into the bar's row, and the name's line in `title200` and in
 * `title50`, measured at the phone's text size.
 */
data class UserProfileHeaderMetrics(
    /** Where the header's picture starts at rest: under the status bar and the bar's row. */
    val topExpanded: Dp,
    val nameExpanded: Dp,
    val nameCollapsed: Dp,
) {
    /** The scroll, in dp, that folds the header whole. */
    val foldDistance: Dp get() = (PictureExpanded - PictureCollapsed) + (nameExpanded - nameCollapsed) + BarRise

    companion object {
        val PictureExpanded: Dp = ThumbnailSize.XLarge.width
        val PictureCollapsed: Dp = ThumbnailSize.Medium.width

        /** Folded, the picture's top is level with the top of the bar's buttons, centred in its row. */
        val BarRise: Dp = TopAppBarDefaults.TopAppBarExpandedHeight - (TopAppBarDefaults.TopAppBarExpandedHeight - PictureCollapsed) / 2

        private const val LINE_SAMPLE: String = "Ag"

        fun of(statusBarHeight: Dp, typography: RecitTypography, measurer: TextMeasurer, density: Density): UserProfileHeaderMetrics =
            with(density) {
                UserProfileHeaderMetrics(
                    topExpanded = statusBarHeight + TopAppBarDefaults.TopAppBarExpandedHeight,
                    nameExpanded = measurer.measure(LINE_SAMPLE, typography.title200).size.height.toDp(),
                    nameCollapsed = measurer.measure(LINE_SAMPLE, typography.title50).size.height.toDp(),
                )
            }
    }
}

@Composable
internal fun rememberUserProfileHeaderMetrics(): UserProfileHeaderMetrics {
    val statusBarHeight: Dp = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val typography: RecitTypography = RecitTheme.typography
    val measurer: TextMeasurer = rememberTextMeasurer()
    val density: Density = LocalDensity.current
    return remember(statusBarHeight, typography, measurer, density) {
        UserProfileHeaderMetrics.of(statusBarHeight.coerceAtLeast(0.dp), typography, measurer, density)
    }
}
