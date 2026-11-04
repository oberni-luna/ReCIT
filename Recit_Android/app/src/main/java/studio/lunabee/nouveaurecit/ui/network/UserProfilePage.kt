package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListItemInfo
import androidx.compose.foundation.lazy.LazyListLayoutInfo
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.filterNotNull
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `UserProfilePage`: one page of a reader's profile, scrolling on its own under the header. Its first row
 * is empty room as tall as the unfolded header, so the scroll offset counts from the page at rest and the
 * header folds by it ([headerOffset]). A scroll that ends inside the fold is carried to the nearer end, and
 * a page too short to fold whole is given the room at its foot to do it: the header never rests halfway.
 */
@Composable
internal fun UserProfilePage(
    state: LazyListState,
    collapse: ProfileHeaderCollapse,
    headerRoom: Dp,
    bottomPadding: Dp,
    content: LazyListScope.() -> Unit,
) {
    var trailingRoom: Float by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(state, collapse) {
        snapshotFlow { state.isScrollInProgress }.filter { !it }.collect {
            val offset: Float = state.headerOffset()
            val resting: Float = collapse.restingOffset(offset)
            if (resting != offset) state.animateScrollBy(resting - offset)
        }
    }
    LaunchedEffect(state, collapse) {
        snapshotFlow { state.layoutInfo.measuredContent() }.filterNotNull().collect { (contentHeight, viewportHeight) ->
            trailingRoom = collapse.trailingRoom(contentHeight, viewportHeight)
        }
    }

    LazyColumn(
        state = state,
        contentPadding = PaddingValues(bottom = bottomPadding + Spacing.large),
        modifier = Modifier.fillMaxSize(),
    ) {
        item(key = HEADER_ROOM) { Spacer(Modifier.height(headerRoom)) }
        content()
        item(key = TRAILING_ROOM) { Spacer(Modifier.height(with(LocalDensity.current) { trailingRoom.toDp() })) }
    }
}

/** How far the page has scrolled from rest, in pixels; past the header's room, further than any fold. */
internal fun LazyListState.headerOffset(): Float =
    if (firstVisibleItemIndex == 0) firstVisibleItemScrollOffset.toFloat() else Float.POSITIVE_INFINITY

/**
 * The height of everything but the trailing room, and of the viewport above the bottom padding — known
 * only while the whole page is on screen, which is the only time a page can be too short.
 */
private fun LazyListLayoutInfo.measuredContent(): Pair<Float, Float>? {
    val first: LazyListItemInfo = visibleItemsInfo.firstOrNull()?.takeIf { it.index == 0 } ?: return null
    val last: LazyListItemInfo = visibleItemsInfo.firstOrNull { it.index == totalItemsCount - 2 } ?: return null
    val contentHeight: Float = (last.offset + last.size - first.offset).toFloat()
    return contentHeight to (viewportSize.height - afterContentPadding).toFloat()
}

private const val HEADER_ROOM: String = "header-room"
private const val TRAILING_ROOM: String = "trailing-room"
