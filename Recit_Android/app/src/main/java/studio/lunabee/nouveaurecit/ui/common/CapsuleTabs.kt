package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.snapshots.SnapshotStateMap
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onPlaced
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import kotlin.math.floor

/**
 * `UserProfileTabPicker`: the words of a [pagerState]'s pages side by side, the selected one in a capsule.
 * The capsule is laid from the pager's position, not from the selection, so it **follows the finger**
 * during a swipe — between the two words by as much of each page as is on screen — and glides when a word
 * is touched and the pager turns to its page. The word the pager is mostly on is drawn as the selected one.
 */
@Composable
fun CapsuleTabs(
    tabs: List<CapsuleTab>,
    pagerState: PagerState,
    modifier: Modifier = Modifier,
) {
    val scope: CoroutineScope = rememberCoroutineScope()
    val spans: SnapshotStateMap<Int, Pair<Float, Float>> = remember { mutableStateMapOf() }
    val capsule: Color = RecitTheme.colors.backgroundTinted
    Row(
        modifier = modifier
            .selectableGroup()
            .drawBehind {
                val position: Float = (pagerState.currentPage + pagerState.currentPageOffsetFraction).coerceIn(0f, tabs.lastIndex.toFloat())
                val lower: Int = floor(position).toInt()
                val from: Pair<Float, Float> = spans[lower] ?: return@drawBehind
                val to: Pair<Float, Float> = spans[minOf(lower + 1, tabs.lastIndex)] ?: from
                val fraction: Float = position - lower
                val left: Float = from.first + (to.first - from.first) * fraction
                val width: Float = from.second + (to.second - from.second) * fraction
                drawRoundRect(
                    color = capsule,
                    topLeft = Offset(left, 0f),
                    size = Size(width, size.height),
                    cornerRadius = CornerRadius(size.height / 2),
                )
            },
    ) {
        tabs.forEachIndexed { index, tab ->
            val isSelected: Boolean = pagerState.currentPage == index
            Text(
                text = tab.label,
                style = RecitTheme.typography.action200,
                color = if (isSelected) RecitTheme.colors.foregroundTinted else RecitTheme.colors.foregroundDefault,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .onPlaced { spans[index] = it.positionInParent().x to it.size.width.toFloat() }
                    .clip(CircleShape)
                    .clickable(role = Role.Tab) { scope.launch { pagerState.animateScrollToPage(index) } }
                    .semantics {
                        contentDescription = tab.description
                        selected = isSelected
                    }
                    .padding(horizontal = Spacing.sMedium, vertical = Spacing.small),
            )
        }
    }
}
