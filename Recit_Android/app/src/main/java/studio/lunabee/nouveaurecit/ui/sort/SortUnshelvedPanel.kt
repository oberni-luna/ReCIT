package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.sorting.SortApplyLedger
import studio.lunabee.nouveaurecit.data.sorting.SortBook
import studio.lunabee.nouveaurecit.data.sorting.SortFooter
import studio.lunabee.nouveaurecit.data.sorting.SortGridMetrics
import studio.lunabee.nouveaurecit.data.sorting.SortSection
import studio.lunabee.nouveaurecit.data.sorting.SortSectionId
import studio.lunabee.nouveaurecit.data.sorting.SortWritePlan
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/** One étagère a book can be filed into without a drag: « Ranger dans… ». */
data class SortFilingOption(val sectionId: SortSectionId, val name: String)

/**
 * `SortUnshelvedPanelView` (feature 0010): anchored to the foot of the surface and never scrolling
 * away, the books on no étagère as a one-row carousel, then the controls and the footer. The grid
 * scrolls underneath and dissolves into it — a gradient from nothing to the background, without the
 * variable blur iOS adds.
 *
 * The header and the carousel are a drop target (a book dragged back here is unshelved), on the
 * panel's layer, so a card seen through the panel does not catch the drop.
 */
@Composable
fun SortUnshelvedPanel(
    unshelved: SortSection,
    bookColumnWidth: Dp,
    filingOptions: List<SortFilingOption>,
    footer: SortFooter,
    hasPendingChanges: Boolean,
    isApplying: Boolean,
    onDrop: (SortBook, SortDropKey) -> Unit,
    onFile: (SortBook, SortSectionId) -> Unit,
    onFileIntoNewShelf: (SortBook) -> Unit,
    onDiscard: () -> Unit,
    onApply: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val key: SortDropKey = SortDropKey.Section(SortSectionId.Unshelved)
    val drag: SortDragState = LocalSortDragState.current
    val isTargeted: Boolean by remember { derivedStateOf { drag.hovered == key } }
    val background: Color = RecitTheme.colors.backgroundDefault

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(Brush.verticalGradient(0f to background.copy(alpha = 0f), 0.35f to background.copy(alpha = 0.92f), 1f to background)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .sortDropTarget(key, layer = SortDropZone.PANEL_LAYER)
                .border(width = 2.dp, color = if (isTargeted) RecitTheme.colors.borderTinted else Color.Transparent)
                .padding(top = Spacing.large),
        ) {
            Text(
                text = stringResource(R.string.sort_unshelved_header, unshelved.bookCount),
                style = RecitTheme.typography.action200,
                color = RecitTheme.colors.foregroundDefault,
                modifier = Modifier.padding(horizontal = Spacing.medium).padding(bottom = Spacing.small),
            )
            if (unshelved.books.isEmpty()) {
                Box(Modifier.fillMaxWidth().height(SortGridMetrics.CARD_HEIGHT.dp), contentAlignment = Alignment.Center) {
                    Text(
                        text = stringResource(R.string.sort_unshelved_empty),
                        style = RecitTheme.typography.content300,
                        color = RecitTheme.colors.foregroundSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
            } else {
                LazyRow(
                    contentPadding = PaddingValues(horizontal = Spacing.medium),
                    horizontalArrangement = Arrangement.spacedBy(SortGridMetrics.BOOK_SPACING.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(SortGridMetrics.CARD_HEIGHT.dp)
                        .graphicsLayer { alpha = if (isApplying) 0.8f else 1f },
                ) {
                    items(unshelved.books, key = { it.id }) { book ->
                        SortBookCard(
                            book = book,
                            width = bookColumnWidth,
                            enabled = !isApplying,
                            filingOptions = if (isApplying) emptyList() else filingOptions,
                            onDrop = onDrop,
                            onFile = { onFile(book, it) },
                            onFileIntoNewShelf = { onFileIntoNewShelf(book) },
                        )
                    }
                }
            }
        }
        // The rule separates the controls from the books; black at 20 %, the shadow of a line.
        HorizontalDivider(color = Color.Black.copy(alpha = 0.2f))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(background.copy(alpha = 0.5f))
                .navigationBarsPadding()
                .padding(horizontal = Spacing.medium)
                .padding(top = Spacing.medium, bottom = Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        ) {
            SortActionBar(
                enabled = hasPendingChanges && !isApplying,
                isApplying = isApplying,
                onDiscard = onDiscard,
                onApply = onApply,
            )
            SortFooterText(footer)
        }
    }
}

/**
 * `SortBookCardView`: a book to file. Only its cover is a drag source; a tap opens « Ranger dans… »,
 * which records exactly the change a drop would — the recommended way of filing books cannot be
 * sighted-only, nor drag-only. TalkBack gets the same choices as custom actions.
 */
@Composable
private fun SortBookCard(
    book: SortBook,
    width: Dp,
    enabled: Boolean,
    filingOptions: List<SortFilingOption>,
    onDrop: (SortBook, SortDropKey) -> Unit,
    onFile: (SortSectionId) -> Unit,
    onFileIntoNewShelf: () -> Unit,
) {
    var showsMenu: Boolean by remember { mutableStateOf(false) }
    val coverWidth: Float = width.value * BOOK_COVER_WIDTH_SHARE
    val coverHeight: Float = minOf(SortGridMetrics.BOOK_ART_HEIGHT, SortGridMetrics.coverSize(coverWidth).height)
    val fileIntoLabels: List<String> = filingOptions.map { stringResource(R.string.sort_file_into, it.name) }
    val newShelfLabel: String = stringResource(R.string.sort_create_shelf)
    val menuLabel: String = stringResource(R.string.sort_file_into_menu)

    Box {
        Column(
            modifier = Modifier
                .width(width)
                .height(SortGridMetrics.CARD_HEIGHT.dp)
                .clickable(enabled = enabled, onClickLabel = menuLabel) { showsMenu = true }
                .padding(vertical = Spacing.xxSmall)
                .semantics {
                    customActions = filingOptions.mapIndexed { index, option ->
                        CustomAccessibilityAction(fileIntoLabels[index]) { onFile(option.sectionId); true }
                    }
                },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        ) {
            // The cells hang from their top edge, so one- and two-line titles keep their covers on one line.
            Box(Modifier.fillMaxWidth().height(SortGridMetrics.BOOK_ART_HEIGHT.dp), contentAlignment = Alignment.BottomCenter) {
                SortCover(
                    book = book,
                    width = coverWidth.dp,
                    height = coverHeight.dp,
                    modifier = Modifier.sortDragSource(book, enabled, onDrop),
                )
            }
            Text(
                text = book.title,
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundDefault,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        DropdownMenu(expanded = showsMenu, onDismissRequest = { showsMenu = false }) {
            filingOptions.forEachIndexed { index, option ->
                DropdownMenuItem(
                    text = { Text(fileIntoLabels[index]) },
                    onClick = {
                        showsMenu = false
                        onFile(option.sectionId)
                    },
                )
            }
            DropdownMenuItem(
                text = { Text(newShelfLabel) },
                onClick = {
                    showsMenu = false
                    onFileIntoNewShelf()
                },
            )
        }
    }
}

/** `ManualSortActionBar`, without the proposal: discard the stack, or save it. */
@Composable
private fun SortActionBar(enabled: Boolean, isApplying: Boolean, onDiscard: () -> Unit, onApply: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium)) {
        FilledTonalIconButton(
            onClick = onDiscard,
            enabled = enabled,
            colors = IconButtonDefaults.filledTonalIconButtonColors(
                containerColor = RecitTheme.colors.backgroundTinted,
                contentColor = RecitTheme.colors.foregroundTinted,
            ),
        ) {
            Icon(Icons.AutoMirrored.Filled.Undo, contentDescription = stringResource(R.string.sort_discard))
        }
        PrimaryButton(
            text = stringResource(R.string.sort_apply),
            onClick = onApply,
            enabled = enabled,
            isLoading = isApplying,
            modifier = Modifier.weight(1f),
        )
    }
}

/**
 * `SortFooterView`: an emplacement, not a line — the recap, a settled run's report, a stopped run's
 * three-part account, or the idle sentence. The panel is anchored, so a long report grows upwards.
 */
@Composable
private fun SortFooterText(footer: SortFooter) {
    val lines: List<Pair<String, Boolean>> = footerLines(footer)
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(Spacing.sMedium)) {
        lines.forEach { (text, isNote) ->
            Text(
                text = text,
                style = if (isNote) RecitTheme.typography.footnote200 else RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

/** Each line of the footer, and whether it is the small print. */
@Composable
private fun footerLines(footer: SortFooter): List<Pair<String, Boolean>> = when (footer) {
    SortFooter.Idle -> listOf(stringResource(R.string.sort_footer_idle) to false)
    SortFooter.IdleWithoutShelves -> listOf(stringResource(R.string.sort_footer_idle_no_shelf) to false)
    is SortFooter.Recap -> listOf(recap(footer.plan) to false)
    is SortFooter.Report -> report(footer.ledger)
}

@Composable
private fun recap(plan: SortWritePlan): String {
    if (!plan.hasWork) return stringResource(R.string.sort_recap_nothing_to_save)
    val clauses: List<String> = plan.summary.clauses.map { clause ->
        when (clause) {
            is SortWritePlan.Summary.Clause.ShelvesToCreate -> pluralStringResource(R.plurals.sort_recap_shelves_to_create, clause.count, clause.count)
            is SortWritePlan.Summary.Clause.ShelvesModified -> pluralStringResource(R.plurals.sort_recap_shelves_modified, clause.count, clause.count)
            is SortWritePlan.Summary.Clause.BooksFiled -> pluralStringResource(R.plurals.sort_recap_books_filed, clause.count, clause.count)
            is SortWritePlan.Summary.Clause.BooksLeftUnshelved -> pluralStringResource(R.plurals.sort_recap_books_left, clause.count, clause.count)
        }
    }
    return clauses.joinToString(", ").replaceFirstChar(Char::uppercase) + "."
}

@Composable
private fun report(ledger: SortApplyLedger): List<Pair<String, Boolean>> {
    val and: String = stringResource(R.string.sort_list_and)
    return when (val result: SortApplyLedger.Result = ledger.result) {
        SortApplyLedger.Result.Running -> emptyList()
        SortApplyLedger.Result.AllLanded -> if (ledger.landedCount == 0) {
            listOf(stringResource(R.string.sort_report_nothing_to_save) to false)
        } else {
            listOf(pluralStringResource(R.plurals.sort_report_all_landed, ledger.landedCount, ledger.landedCount) to false)
        }
        is SortApplyLedger.Result.Stopped -> buildList {
            add(stringResource(R.string.sort_report_stopped) to false)
            if (result.landed.isEmpty()) {
                add(stringResource(R.string.sort_report_stopped_none_landed) to false)
            } else {
                add(pluralStringResource(R.plurals.sort_report_stopped_landed, result.landed.size, result.landed.size, joinNames(result.landed, and)) to false)
            }
            if (result.failed.isNotEmpty()) {
                add(pluralStringResource(R.plurals.sort_report_stopped_failed, result.failed.size, result.failed.size, joinNames(result.failed, and)) to false)
            }
            if (result.notAttempted.isNotEmpty()) {
                add(
                    pluralStringResource(
                        R.plurals.sort_report_stopped_not_attempted,
                        result.notAttempted.size,
                        result.notAttempted.size,
                        joinNames(result.notAttempted, and),
                    ) to false,
                )
            }
            add(stringResource(R.string.sort_report_stopped_resume) to true)
        }
    }
}

/** `.formatted(.list(type: .and))`: « A, B et C ». */
internal fun joinNames(names: List<String>, and: String): String = when (names.size) {
    0 -> ""
    1 -> names.single()
    else -> names.dropLast(1).joinToString(", ") + " $and " + names.last()
}

/** A book card's cover takes 62 % of the card's width. */
private const val BOOK_COVER_WIDTH_SHARE: Float = 0.62f
