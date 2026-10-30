package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.PagerDefaults
import androidx.compose.foundation.pager.PagerSnapDistance
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import coil3.compose.AsyncImage
import kotlinx.coroutines.flow.drop
import studio.lunabee.nouveaurecit.data.lists.CoverFlowGeometry
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.initialsOf
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * `ListCoverFlowView` (iOS feature 0060): a list's covers in a horizontal strip that snaps, the one facing
 * the reader being the selection. The others are turned in perspective, pushed aside and shaded by
 * [CoverFlowGeometry]; a list of authors shows portraits in discs.
 *
 * **A real pager, not a gesture of our own**: inertia and snapping come from [HorizontalPager], whose
 * pages are empty slots one `STEP` wide — a swipe moves one book at most. The covers are drawn above
 * them, each posed in a `graphicsLayer` from the pager's position, so a frame of the swipe recomposes
 * nothing; their order follows the distance to the centre, nearest on top.
 *
 * Tapping a turned cover brings it to the front; tapping the one in front opens its page.
 */
@Composable
internal fun ListCoverFlow(
    rows: List<ListElementRowModel>,
    isAuthor: Boolean,
    selectedUri: String?,
    onSelect: (String) -> Unit,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val selectedIndex: Int = rows.indexOfFirst { it.uri == selectedUri }.coerceAtLeast(0)
    val pagerState: PagerState = rememberPagerState(initialPage = selectedIndex) { rows.size }
    val currentRows: State<List<ListElementRowModel>> = rememberUpdatedState(rows)
    val currentOnSelect: State<(String) -> Unit> = rememberUpdatedState(onSelect)
    val haptics: HapticFeedback = LocalHapticFeedback.current
    val geometry: CoverFlowGeometry = CoverFlowGeometry(coverWidth = COVER_WIDTH.value)

    // The selection moved without the finger — an add, a removal: the strip follows it.
    LaunchedEffect(selectedIndex, rows.size) {
        if (rows.isNotEmpty() && pagerState.currentPage != selectedIndex && !pagerState.isScrollInProgress) {
            pagerState.animateScrollToPage(selectedIndex)
        }
    }
    // The finger moved the strip: the cover it settled on is the selection. Only changes count, so a list
    // changing under a still strip never overrides what the view model chose.
    LaunchedEffect(pagerState) {
        snapshotFlow { pagerState.settledPage }.drop(1).collect { page ->
            currentRows.value.getOrNull(page)?.uri?.let { currentOnSelect.value(it) }
        }
    }
    LaunchedEffect(pagerState) {
        snapshotFlow { pagerState.currentPage }.drop(1).collect { haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove) }
    }

    BoxWithConstraints(modifier.fillMaxWidth().height(STRIP_HEIGHT)) {
        val density: Density = LocalDensity.current
        val sidePadding: Dp = ((maxWidth - CoverFlowGeometry.STEP.dp) / 2).coerceAtLeast(0.dp)
        val position: () -> Float = { pagerState.currentPage + pagerState.currentPageOffsetFraction }

        Box(
            Modifier
                .fillMaxSize()
                .pointerInput(rows, isAuthor) {
                    detectTapGestures { tap ->
                        val hit: Int = coverAt(tap.x - size.width / 2f, position(), rows.size, geometry, density) ?: return@detectTapGestures
                        val uri: String = currentRows.value.getOrNull(hit)?.uri ?: return@detectTapGestures
                        if (hit == pagerState.currentPage) onOpen(uri) else currentOnSelect.value(uri)
                    }
                },
        ) {
            val current: Int = pagerState.currentPage
            val visible: IntRange = (current - VISIBLE_RANK).coerceAtLeast(0)..(current + VISIBLE_RANK).coerceAtMost(rows.size - 1)
            for (index in visible) {
                val row: ListElementRowModel = rows[index]
                key(row.uri) {
                    ListCoverFlowItem(
                        row = row,
                        isAuthor = isAuthor,
                        isFront = index == current,
                        onOpen = { onOpen(row.uri) },
                        onSelect = { onSelect(row.uri) },
                        shade = { geometry.placement((index - position()) * CoverFlowGeometry.STEP).shade },
                        modifier = Modifier
                            .align(Alignment.Center)
                            .zIndex(-abs(index - current).toFloat())
                            .coverPlacement(index, position, geometry, density),
                    )
                }
            }
            HorizontalPager(
                state = pagerState,
                pageSize = PageSize.Fixed(CoverFlowGeometry.STEP.dp),
                contentPadding = PaddingValues(horizontal = sidePadding),
                flingBehavior = PagerDefaults.flingBehavior(pagerState, pagerSnapDistance = PagerSnapDistance.atMost(1)),
                key = { currentRows.value.getOrNull(it)?.uri ?: it },
                modifier = Modifier.fillMaxSize().zIndex(1f),
            ) {
                Box(Modifier.fillMaxSize())
            }
        }
    }
}

/** A cover posed from its distance to the strip's centre, read at draw time. */
private fun Modifier.coverPlacement(index: Int, position: () -> Float, geometry: CoverFlowGeometry, density: Density): Modifier =
    graphicsLayer {
        val distance: Float = (index - position()) * CoverFlowGeometry.STEP
        val placement: CoverFlowGeometry.Placement = geometry.placement(distance)
        translationX = with(density) { (distance + placement.offset).dp.toPx() }
        // Compose turns the other way round from SwiftUI's `rotation3DEffect`.
        rotationY = placement.angle
        scaleX = placement.scale
        scaleY = placement.scale
        cameraDistance = CAMERA_DISTANCE * density.density
    }

/**
 * Which cover a tap [x] pixels from the strip's centre lands on: the nearest to the centre among those
 * it falls within — the one drawn on top.
 */
private fun coverAt(x: Float, position: Float, count: Int, geometry: CoverFlowGeometry, density: Density): Int? {
    if (count == 0) return null
    val current: Int = position.roundToInt().coerceIn(0, count - 1)
    val candidates: List<Int> = ((current - VISIBLE_RANK).coerceAtLeast(0)..(current + VISIBLE_RANK).coerceAtMost(count - 1))
        .sortedBy { abs(it - current) }
    return candidates.firstOrNull { index ->
        val distance: Float = (index - position) * CoverFlowGeometry.STEP
        val placement: CoverFlowGeometry.Placement = geometry.placement(distance)
        val centre: Float = with(density) { (distance + placement.offset).dp.toPx() }
        val halfWidth: Float = with(density) {
            val seen: Float = if (index == current) geometry.coverWidth else geometry.turnedWidth
            (seen * placement.scale / 2).dp.toPx()
        }
        abs(x - centre) <= halfWidth
    }
}

/** `ListCoverFlowItem`: a cover, or a portrait in a disc for an author; a title stands in for no image. */
@Composable
private fun ListCoverFlowItem(
    row: ListElementRowModel,
    isAuthor: Boolean,
    isFront: Boolean,
    onOpen: () -> Unit,
    onSelect: () -> Unit,
    shade: () -> Float,
    modifier: Modifier = Modifier,
) {
    val shape: Shape = if (isAuthor) CircleShape else RoundedCornerShape(CornerRadius.minimal)
    val height: Dp = if (isAuthor) COVER_WIDTH else COVER_WIDTH * 3 / 2
    Box(
        modifier = modifier
            .size(width = COVER_WIDTH, height = height)
            .shadow(elevation = 6.dp, shape = shape)
            .clip(shape)
            .background(RecitTheme.colors.backgroundSecondary)
            .semantics(mergeDescendants = true) {
                contentDescription = row.title
                onClick { if (isFront) onOpen() else onSelect(); true }
            },
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = if (isAuthor) initialsOf(row.title) else row.title,
            style = if (isAuthor) RecitTheme.typography.title200 else RecitTheme.typography.content300,
            color = RecitTheme.colors.foregroundSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(Spacing.small),
        )
        if (row.image != null) {
            AsyncImage(
                model = row.image,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
        // The row fades back on both sides: each rank away from the centre a little darker.
        Box(
            Modifier
                .fillMaxSize()
                .drawWithContent {
                    val alpha: Float = shade()
                    if (alpha > 0f) drawRect(Color.Black.copy(alpha = alpha))
                },
        )
    }
}

/** The width of the cover facing the reader. */
private val COVER_WIDTH: Dp = 160.dp

/** The cover facing the reader, a little room above and below for its shadow. */
private val STRIP_HEIGHT: Dp = COVER_WIDTH * 3 / 2 + 32.dp

/** How many covers are drawn on each side of the one in front. */
private const val VISIBLE_RANK: Int = 6

/** `rotation3DEffect`'s perspective 0.5, roughly, in Compose's units. */
private const val CAMERA_DISTANCE: Float = 12f
