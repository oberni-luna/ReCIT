package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.ShelfPalette
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.shelfPaper

/*
 * The non-search half of the Inventaire tab: `InventorySyncBanner`, `ShelfSectionHeader`, the
 * carousel of `ShelfRowView` cards and `ShelfEmptyStateView` (feature 0021).
 */

/** `InventorySyncBanner` for my own first sync (feature 0027). */
@Composable
internal fun InventorySyncBanner(state: FirstSyncState, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(RecitTheme.colors.backgroundSecondary)
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
            Text(
                text = stringResource(R.string.inventory_sync_mine_title),
                style = RecitTheme.typography.action300,
                color = RecitTheme.colors.foregroundDefault,
                modifier = Modifier.weight(1f),
            )
            val percent: Int? = state.percent
            if (percent != null) {
                Text(
                    text = stringResource(R.string.inventory_sync_percent, percent),
                    style = RecitTheme.typography.footnote200,
                    color = RecitTheme.colors.foregroundSecondary,
                )
            } else {
                CircularProgressIndicator(modifier = Modifier.size(14.dp), strokeWidth = 2.dp, color = RecitTheme.colors.foregroundSecondary)
            }
        }
        val fraction: Float? = state.fraction
        if (fraction != null) {
            LinearProgressIndicator(
                progress = { fraction },
                modifier = Modifier.fillMaxWidth(),
                color = RecitTheme.colors.foregroundTinted,
                trackColor = RecitTheme.colors.backgroundDisable,
            )
        } else {
            LinearProgressIndicator(
                modifier = Modifier.fillMaxWidth(),
                color = RecitTheme.colors.foregroundTinted,
                trackColor = RecitTheme.colors.backgroundDisable,
            )
        }
        Text(
            text = syncCaption(state),
            style = RecitTheme.typography.footnote200,
            color = RecitTheme.colors.foregroundSecondary,
        )
    }
}

@Composable
private fun syncCaption(state: FirstSyncState): String = when (state) {
    FirstSyncState.Synced -> ""
    FirstSyncState.Waiting -> stringResource(R.string.inventory_sync_waiting)
    is FirstSyncState.Running -> {
        val total: Int? = state.progress.announced
        if (total != null) {
            stringResource(R.string.inventory_sync_count_arriving, state.progress.received, total)
        } else {
            stringResource(R.string.inventory_sync_preparing)
        }
    }
}

/** `ShelfSectionHeader`: action200 in the default colour, with an optional tinted « + » action. */
@Composable
internal fun ShelvesSectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    actionTitle: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .padding(bottom = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = RecitTheme.typography.action200,
            color = RecitTheme.colors.foregroundDefault,
            modifier = Modifier.weight(1f).padding(vertical = Spacing.small),
        )
        if (actionTitle != null && onAction != null) {
            TextButton(onClick = onAction, contentPadding = PaddingValues(start = Spacing.small, end = Spacing.zero)) {
                Icon(Icons.Default.Add, contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(Spacing.xSmall))
                Text(actionTitle, style = RecitTheme.typography.action200, color = RecitTheme.colors.foregroundTinted)
            }
        }
    }
}

/**
 * The horizontal, snapping carousel of shelves: cards of 86 % of the width, 14 apart, the current
 * one centred between its neighbours' edges. A shelf that appears while the carousel is on screen
 * — one just created — is scrolled to. [onAddBooks], on my shelves only, puts a « Ajouter des
 * livres » tag on an empty plank.
 */
@Composable
internal fun ShelfCarousel(
    shelves: List<ShelfWithItems>,
    onOpenShelf: (String) -> Unit,
    onOpenItem: (String) -> Unit,
    onAddBooks: ((ShelfWithItems) -> Unit)? = null,
) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val cardWidth: Dp = maxWidth * ShelfCardMetrics.CARD_WIDTH_FRACTION
        val pagerState: PagerState = rememberPagerState { shelves.size }
        val ids: List<String> = shelves.map { it.shelf.id }
        var knownIds: List<String> by remember { mutableStateOf(ids) }
        LaunchedEffect(ids) {
            val added: Int = ids.indexOfFirst { it !in knownIds }
            knownIds = ids
            if (added >= 0) pagerState.animateScrollToPage(added)
        }
        HorizontalPager(
            state = pagerState,
            pageSize = PageSize.Fixed(cardWidth),
            pageSpacing = ShelfCardMetrics.GUTTER.dp,
            contentPadding = PaddingValues(horizontal = (maxWidth - cardWidth) / 2),
            key = { index -> shelves[index].shelf.id },
            verticalAlignment = Alignment.Top,
        ) { index ->
            val shelf: ShelfWithItems = shelves[index]
            ShelfCard(
                shelf = shelf,
                width = cardWidth,
                onOpen = { onOpenShelf(shelf.shelf.id) },
                onOpenItem = onOpenItem,
                onAddBooks = onAddBooks?.let { add -> { add(shelf) } },
            )
        }
    }
}

/** `ShelfRowView`, simplified: the first covers standing on the plank, and the paper name tag. */
@Composable
private fun ShelfCard(
    shelf: ShelfWithItems,
    width: Dp,
    onOpen: () -> Unit,
    onOpenItem: (String) -> Unit,
    onAddBooks: (() -> Unit)?,
) {
    val metrics = ShelfCardMetrics(width.value)
    val drawn: List<ItemRow> = ShelfDrawnBooks.from(shelf.items).take(metrics.fittingCount)
    Column(modifier = Modifier.width(width), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(metrics.topRoom.dp))
        Box(
            modifier = Modifier.width(width).height(metrics.zoneHeight.dp).padding(horizontal = ShelfCardMetrics.HORIZONTAL_MARGIN.dp),
            contentAlignment = if (drawn.isEmpty()) Alignment.BottomCenter else Alignment.BottomStart,
        ) {
            if (drawn.isEmpty() && onAddBooks != null) {
                ShelfActionTag(
                    icon = Icons.Default.Add,
                    title = stringResource(R.string.shelf_empty_action_add_title),
                    detail = stringResource(R.string.shelf_empty_action_add_detail),
                    onClick = onAddBooks,
                    modifier = Modifier.padding(bottom = Spacing.xxSmall),
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(ShelfCardMetrics.COVER_GAP.dp), verticalAlignment = Alignment.Bottom) {
                drawn.forEach { row ->
                    StandingCover(
                        row = row,
                        width = metrics.coverWidth.dp,
                        height = metrics.coverHeight.dp,
                        onClick = { onOpenItem(row.item.id) },
                    )
                }
            }
        }
        Plank(width = width, height = metrics.plankHeight.dp)
        ShelfLabel(
            text = shelf.shelf.name,
            maxWidth = metrics.booksWidth.dp,
            onClick = onOpen,
            modifier = Modifier.offset(y = -ShelfCardMetrics.LABEL_OVERLAP.dp),
        )
    }
}

/** A copy standing face-on on a plank. Without [onClick] it is an illustration: nothing answers a tap. */
@Composable
internal fun StandingCover(row: ItemRow, width: Dp, height: Dp, onClick: (() -> Unit)?) {
    val shape = RoundedCornerShape(topStart = 2.dp, topEnd = 2.dp)
    Box(
        modifier = Modifier
            .size(width = width, height = height)
            .shadow(elevation = 2.dp, shape = shape)
            .clip(shape)
            .background(ShelfPalette.Parchment)
            .then(if (onClick != null) Modifier.clickable(onClickLabel = row.title, onClick = onClick) else Modifier),
    ) {
        if (!row.image.isNullOrEmpty()) {
            AsyncImage(model = row.image, contentDescription = row.title, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        } else {
            Text(
                text = row.title,
                style = RecitTheme.typography.footnote200,
                color = ShelfPalette.LabelInk,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(Spacing.xSmall),
            )
        }
    }
}

@Composable
internal fun Plank(width: Dp, height: Dp) {
    Image(
        painter = painterResource(R.drawable.shelf_plank),
        contentDescription = null,
        contentScale = ContentScale.FillBounds,
        modifier = Modifier.size(width = width, height = height),
    )
}

/** `ShelfLabelView`: « • name • » on tilted paper. Tapping it opens the shelf. */
@Composable
private fun ShelfLabel(text: String, maxWidth: Dp, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .widthIn(max = maxWidth)
            .shelfPaper(text)
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.small, vertical = Spacing.xSmall),
        horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(BULLET, style = RecitTheme.typography.content300, color = ShelfPalette.LabelInk)
        Text(
            text = text,
            style = RecitTheme.typography.content300,
            color = ShelfPalette.LabelInk,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f, fill = false),
        )
        Text(BULLET, style = RecitTheme.typography.content300, color = ShelfPalette.LabelInk)
    }
}

/**
 * `ShelfEmptyStateView` (feature 0021): the step the user is at, written above the plank, and the
 * paper tags that take it. With no book yet, « Scanner » opens the scan flow and « Rechercher » the
 * search; with books but no étagère, « Ranger mes livres » opens the sorting surface.
 */
@Composable
internal fun EmptyShelfCard(ownsBooks: Boolean, onScan: () -> Unit, onSearch: () -> Unit, onSort: () -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        val width: Dp = maxWidth * ShelfCardMetrics.CARD_WIDTH_FRACTION
        val metrics = ShelfCardMetrics(width.value)
        Column(
            modifier = Modifier.width(width).padding(top = Spacing.small),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            Column(
                modifier = Modifier.width(metrics.booksWidth.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
            ) {
                Text(
                    text = stringResource(if (ownsBooks) R.string.shelf_empty_sort_heading else R.string.shelf_empty_scan_heading),
                    style = RecitTheme.typography.content400Bold,
                    color = RecitTheme.colors.foregroundDefault,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.semantics { heading() },
                )
                Text(
                    text = stringResource(if (ownsBooks) R.string.shelf_empty_sort_body else R.string.shelf_empty_scan_body),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundSecondary,
                    textAlign = TextAlign.Center,
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                if (ownsBooks) {
                    ShelfActionTag(
                        icon = Icons.AutoMirrored.Filled.LibraryBooks,
                        title = stringResource(R.string.shelf_empty_action_sort_title),
                        detail = stringResource(R.string.shelf_empty_action_sort_detail),
                        onClick = onSort,
                        modifier = Modifier.padding(bottom = Spacing.xxSmall),
                    )
                } else {
                    Row(
                        modifier = Modifier.padding(bottom = Spacing.xxSmall),
                        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
                    ) {
                        ShelfActionTag(
                            icon = Icons.Default.QrCodeScanner,
                            title = stringResource(R.string.shelf_empty_action_scan_title),
                            detail = stringResource(R.string.shelf_empty_action_scan_detail),
                            onClick = onScan,
                        )
                        ShelfActionTag(
                            icon = Icons.Default.Search,
                            title = stringResource(R.string.shelf_empty_action_search_title),
                            detail = stringResource(R.string.shelf_empty_action_search_detail),
                            onClick = onSearch,
                        )
                    }
                }
                Plank(width = width, height = metrics.plankHeight.dp)
            }
        }
    }
}

/** `ShelfActionTag`: a glyph, a title and its detail, on paper. */
@Composable
private fun ShelfActionTag(icon: ImageVector, title: String, detail: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .shelfPaper(title)
            .clickable(onClickLabel = detail, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Icon(icon, contentDescription = null, tint = ShelfPalette.LabelInk, modifier = Modifier.size(18.dp))
            Text(title, style = RecitTheme.typography.content400Bold, color = ShelfPalette.LabelInk, maxLines = 1)
        }
        Text(detail, style = RecitTheme.typography.footnote200, color = ShelfPalette.LabelInk, maxLines = 2, textAlign = TextAlign.Center)
    }
}

private const val BULLET: String = "•"
