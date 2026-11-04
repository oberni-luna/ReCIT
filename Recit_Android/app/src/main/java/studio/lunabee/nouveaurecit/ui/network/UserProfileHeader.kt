package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.PagerState
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.text.lerp
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.lerp
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.CapsuleTab
import studio.lunabee.nouveaurecit.ui.common.CapsuleTabs

/**
 * `UserProfileStickyHeader`: a reader's picture and name, and the capsule of their pages, laid over the
 * pages from the top of the screen. At rest the picture sits under the bar, at 96 dp, the name in
 * `title200`; as the page on screen scrolls ([progress]) the picture shrinks to 48 dp and rises into the
 * bar's row, between the way back and « … », and the name comes down to `title50`. The backdrop and the
 * hairline at its foot show only once the page passes under it ([backdrop]). Both are read here, so a
 * scroll redraws the header and not the pages.
 *
 * Only the capsule takes touches: everywhere else a finger goes through to the page below.
 */
@Composable
internal fun UserProfileHeader(
    user: UserEntity,
    progress: () -> Float,
    backdrop: () -> Float,
    metrics: UserProfileHeaderMetrics,
    tabs: List<CapsuleTab>?,
    pagerState: PagerState,
    onHeightChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val fold: Float = progress()
    val shade: Float = backdrop()
    val pictureSize: Dp = lerp(UserProfileHeaderMetrics.PictureExpanded, UserProfileHeaderMetrics.PictureCollapsed, fold)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundDefault.copy(alpha = shade))
            .onSizeChanged { onHeightChange(it.height) },
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(metrics.topExpanded - UserProfileHeaderMetrics.BarRise * fold))
        Box(Modifier.size(pictureSize), contentAlignment = Alignment.Center) {
            CellThumbnail(
                url = user.avatarUrl,
                size = ThumbnailSize.XLarge,
                shape = ThumbnailShape.Circle,
                fallbackName = user.username,
                modifier = Modifier
                    .requiredSize(UserProfileHeaderMetrics.PictureExpanded)
                    .graphicsLayer {
                        val scale: Float = pictureSize / UserProfileHeaderMetrics.PictureExpanded
                        scaleX = scale
                        scaleY = scale
                    },
            )
        }
        Spacer(Modifier.height(Spacing.small))
        Box(
            modifier = Modifier
                .height(lerp(metrics.nameExpanded, metrics.nameCollapsed, fold))
                .padding(horizontal = Spacing.medium),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = user.username,
                style = lerp(RecitTheme.typography.title200, RecitTheme.typography.title50, fold),
                color = RecitTheme.colors.foregroundDefault,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        if (tabs != null) {
            Spacer(Modifier.height(Spacing.medium))
            CapsuleTabs(tabs = tabs, pagerState = pagerState)
        }
        Spacer(Modifier.height(Spacing.small))
        HorizontalDivider(Modifier.alpha(shade), color = RecitTheme.colors.borderDefault)
    }
}
