package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.InfiniteTransition
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.sorting.SortApplyLedger
import studio.lunabee.nouveaurecit.data.sorting.SortBook
import studio.lunabee.nouveaurecit.data.sorting.SortGridMetrics
import studio.lunabee.nouveaurecit.data.sorting.SortPile
import studio.lunabee.nouveaurecit.data.sorting.SortSection
import studio.lunabee.nouveaurecit.data.sorting.SortWritePlan
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.TagStyle

/**
 * `SortShelfCardView` (feature 0010): one étagère on the grid — a fanned pile of its first covers,
 * its name and how many books it holds, and the pill saying what saving will do to it. The whole card
 * is a drop target; only the front cover is a drag source, and the rest of the card taps through to
 * the étagère as it will be.
 *
 * While a run writes, étagères it has not landed yet dim to 80 %, the ones waiting or in flight
 * breathe, the one in flight carries a spinner, and one that failed keeps a badge. Squared off and
 * outlined, white throughout, as the device rounds of 0010 left it.
 */
@Composable
fun SortShelfCard(
    section: SortSection,
    status: SortWritePlan.ShelfStatus,
    outcome: SortApplyLedger.ShelfOutcome?,
    isApplying: Boolean,
    width: Dp,
    onOpen: () -> Unit,
    onDrop: (SortBook, SortDropKey) -> Unit,
    onUnshelve: (SortBook) -> Unit,
) {
    val key: SortDropKey = SortDropKey.Section(section.id)
    val drag: SortDragState = LocalSortDragState.current
    val isTargeted: Boolean by remember(key) { derivedStateOf { drag.hovered == key } }
    val pile: SortPile = remember(section) { SortPile(section) }
    val name: String = section.name.orEmpty()
    val title: String = if (pile.bookCount == 0) name else stringResource(R.string.sort_card_title, name, pile.bookCount)
    val pillText: String? = when (status) {
        SortWritePlan.ShelfStatus.New -> stringResource(R.string.sort_pill_new)
        SortWritePlan.ShelfStatus.Modified -> stringResource(R.string.sort_pill_modified)
        SortWritePlan.ShelfStatus.Untouched -> null
    }
    val breathes: Boolean = isApplying && (outcome == SortApplyLedger.ShelfOutcome.Pending || outcome == SortApplyLedger.ShelfOutcome.Applying)
    val alpha: Float = breathingAlpha(breathes, dimmed = isApplying && outcome != SortApplyLedger.ShelfOutcome.Landed)
    val unshelveLabel: String? = pile.draggableBook?.let { stringResource(R.string.sort_unshelve, it.title) }
    val accessibleTitle: String = listOfNotNull(title, pillText).joinToString(", ")
    val applyingLabel: String = stringResource(R.string.sort_mark_applying)

    Box(
        modifier = Modifier
            .width(width)
            .height(SortGridMetrics.CARD_HEIGHT.dp)
            .sortDropTarget(key)
            .graphicsLayer {
                val scale: Float = if (isTargeted) TARGETED_SCALE else 1f
                scaleX = scale
                scaleY = scale
                this.alpha = alpha
            }
            .background(RecitTheme.colors.backgroundDefault)
            .border(
                width = if (isTargeted) 2.dp else 1.dp,
                color = if (isTargeted) RecitTheme.colors.borderTinted else RecitTheme.colors.borderDefault,
            )
            .clickable(onClickLabel = accessibleTitle, onClick = onOpen)
            .semantics {
                val book: SortBook? = pile.draggableBook
                if (book != null && unshelveLabel != null && !isApplying) {
                    customActions = listOf(CustomAccessibilityAction(unshelveLabel) { onUnshelve(book); true })
                }
            },
    ) {
        Column(Modifier.fillMaxSize()) {
            SortPileView(pile = pile, width = width, enabled = !isApplying, onDrop = onDrop)
            Text(
                text = title,
                style = RecitTheme.typography.footnote200Bold,
                color = RecitTheme.colors.foregroundDefault,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.xSmall),
            )
        }
        if (pillText != null) {
            TagLabel(
                text = pillText,
                style = if (status == SortWritePlan.ShelfStatus.New) TagStyle.Tinted else TagStyle.Secondary,
                modifier = Modifier.align(Alignment.TopEnd).padding(Spacing.xSmall),
            )
        }
        when (outcome) {
            SortApplyLedger.ShelfOutcome.Applying -> CircularProgressIndicator(
                color = RecitTheme.colors.foregroundTinted,
                strokeWidth = 2.dp,
                modifier = Modifier.align(Alignment.Center).size(24.dp).semantics { contentDescription = applyingLabel },
            )
            SortApplyLedger.ShelfOutcome.Failed -> Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = stringResource(R.string.sort_mark_failed),
                tint = RecitTheme.colors.foregroundError,
                modifier = Modifier.align(Alignment.TopStart).padding(Spacing.xSmall).size(20.dp),
            )
            else -> Unit
        }
    }
}

/**
 * `SortPileView`: the covers drawn back to front, so the front one — the one a drag takes — ends on
 * top. The fan opens both ways around it; an empty étagère is a dashed hole.
 */
@Composable
private fun SortPileView(pile: SortPile, width: Dp, enabled: Boolean, onDrop: (SortBook, SortDropKey) -> Unit) {
    Box(Modifier.fillMaxWidth().height(SortGridMetrics.ART_HEIGHT.dp), contentAlignment = Alignment.Center) {
        if (pile.isEmpty) {
            val hole: SortGridMetrics.CoverSize = SortGridMetrics.pileCoverSize(width.value, isSingleCover = false)
            val dash: Color = RecitTheme.colors.borderDefault
            Box(
                Modifier
                    .size(hole.width.dp, hole.height.dp)
                    .drawBehind {
                        drawRect(dash, style = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx()))))
                    },
            )
            return@Box
        }
        val size: SortGridMetrics.CoverSize = SortGridMetrics.pileCoverSize(width.value, pile.isSingleCover)
        val inset: Float = if (pile.isSingleCover) 0f else SortGridMetrics.pileVerticalInset(width.value)
        pile.covers.asReversed().forEach { cover ->
            val fan: SortGridMetrics.FanOffset = SortGridMetrics.fanOffset(cover.depth, width.value)
            val isFront: Boolean = cover.depth == 0
            SortCover(
                book = cover.book,
                width = size.width.dp,
                height = size.height.dp,
                modifier = Modifier
                    .offset(fan.x.dp, (fan.y - inset).dp)
                    // Attached below the tilt, so what lifts is the cover as drawn, square and whole.
                    .then(if (isFront) Modifier.sortDragSource(cover.book, enabled, onDrop) else Modifier)
                    .rotate(cover.tiltDegrees.toFloat()),
            )
        }
    }
}

/**
 * A cover in its reserved 2:3 frame, filling it: a fitted cover leaves transparent bands, and a drag
 * would lift them with the artwork. Without an image, the title on parchment.
 */
@Composable
fun SortCover(book: SortBook, width: Dp, height: Dp, modifier: Modifier = Modifier) {
    Box(modifier.size(width, height).background(ShelfPalette.Parchment)) {
        if (!book.coverImageUrl.isNullOrEmpty()) {
            AsyncImage(model = book.coverImageUrl, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        } else {
            Text(
                text = book.title,
                style = RecitTheme.typography.footnote200,
                color = ShelfPalette.LabelInk,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(Spacing.xxSmall),
            )
        }
    }
}

/** `SortNewShelfTileView`: the grid's last tile — tap to create an étagère, or drop a book on it to create it full. */
@Composable
fun SortNewShelfTile(width: Dp, enabled: Boolean, onClick: () -> Unit) {
    val drag: SortDragState = LocalSortDragState.current
    val isTargeted: Boolean by remember { derivedStateOf { drag.hovered == SortDropKey.NewShelf } }
    val tint: Color = RecitTheme.colors.borderTinted
    Column(
        modifier = Modifier
            .width(width)
            .height(SortGridMetrics.CARD_HEIGHT.dp)
            .sortDropTarget(SortDropKey.NewShelf)
            .graphicsLayer {
                val scale: Float = if (isTargeted) TARGETED_SCALE else 1f
                scaleX = scale
                scaleY = scale
            }
            .background(RecitTheme.colors.backgroundTinted)
            .drawBehind {
                val stroke: Stroke = if (isTargeted) {
                    Stroke(width = 2.dp.toPx())
                } else {
                    Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx())))
                }
                drawRect(tint, style = stroke)
            }
            .clickable(enabled = enabled, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(Modifier.fillMaxWidth().height(SortGridMetrics.ART_HEIGHT.dp), contentAlignment = Alignment.Center) {
            Icon(Icons.Default.Add, contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.size(28.dp))
        }
        Text(
            text = stringResource(R.string.sort_create_shelf),
            style = RecitTheme.typography.footnote200Bold,
            color = RecitTheme.colors.foregroundTinted,
            textAlign = TextAlign.Center,
        )
    }
}

/** 80 % while a run is writing and this étagère has not landed; breathing below that while it waits or is written. */
@Composable
private fun breathingAlpha(breathes: Boolean, dimmed: Boolean): Float {
    val transition: InfiniteTransition = rememberInfiniteTransition(label = "sort.breathing")
    val breath: State<Float> = transition.animateFloat(
        initialValue = DIMMED_ALPHA,
        targetValue = BREATH_LOW_ALPHA,
        animationSpec = infiniteRepeatable(tween(BREATH_MILLIS, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "sort.breath",
    )
    return when {
        breathes -> breath.value
        dimmed -> DIMMED_ALPHA
        else -> 1f
    }
}

private const val TARGETED_SCALE: Float = 1.03f
private const val DIMMED_ALPHA: Float = 0.8f
private const val BREATH_LOW_ALPHA: Float = 0.5f
private const val BREATH_MILLIS: Int = 600
