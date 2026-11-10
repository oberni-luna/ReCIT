package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.outlined.Outbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Density
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.groupedCell
import studio.lunabee.nouveaurecit.ui.book.InventoryItemRowWithActions
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination

/**
 * `ShelfBooksPage` (iOS feature 0089): the étagère's books in one inset grouped card, newest first; a touch opens
 * the Fiche livre. On mine, a swipe takes a book off and « Ajouter des livres » is pinned at the foot, sliding
 * with the page. Empty, the shelf icon of « Ranger mes livres » and « Cette étagère est vide », no action: the
 * pinned button is the way in.
 */
@Composable
internal fun ShelfBooksPage(
    books: List<ItemRow>,
    shelfName: String,
    onPush: (Destination) -> Unit,
    onRemove: ((String) -> Unit)?,
    onAddBooks: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    Column(modifier.fillMaxSize()) {
        Box(Modifier.weight(1f).fillMaxWidth()) {
            if (books.isEmpty()) {
                EmptyState(
                    title = stringResource(R.string.shelf_detail_empty),
                    icon = Icons.AutoMirrored.Filled.LibraryBooks,
                    modifier = Modifier.align(Alignment.Center),
                )
            } else {
                LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(vertical = Spacing.small)) {
                    itemsIndexed(books, key = { _, row -> row.item.id }) { index, row ->
                        val open: () -> Unit = { onPush(Destination.Book(BookAnchor.Item(row.item.id))) }
                        Column(Modifier.groupedCell(index, books.size, RecitTheme.colors.backgroundGroupedCell)) {
                            if (index > 0) HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
                            if (onRemove != null) {
                                RemovableRow(row = row, shelfName = shelfName, onOpen = open, onPush = onPush, onRemove = { onRemove(row.item.id) })
                            } else {
                                InventoryItemRowWithActions(row = row, showsOwner = false, onClick = open, onPush = onPush)
                            }
                        }
                    }
                }
            }
        }
        if (onAddBooks != null) {
            ShelfPinnedButton(
                text = stringResource(R.string.shelf_empty_action_add_title),
                onClick = onAddBooks,
                background = RecitTheme.colors.backgroundGrouped,
            )
        }
    }
}

/**
 * `.swipeActions(edge: .trailing, allowsFullSwipe: true)` — « Retirer de %@ », in red: the book leaves the
 * étagère, and the accent's green read as a harmless action.
 */
@Composable
private fun RemovableRow(row: ItemRow, shelfName: String, onOpen: () -> Unit, onPush: (Destination) -> Unit, onRemove: () -> Unit) {
    val dismissState: SwipeToDismissBoxState = rememberDeliberateDismissState()
    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = false,
        onDismiss = { value -> if (value == SwipeToDismissBoxValue.EndToStart) onRemove() },
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(RecitTheme.colors.foregroundError)
                    .padding(horizontal = Spacing.medium),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    Icon(Icons.Outlined.Outbox, contentDescription = null, tint = RecitTheme.colors.foregroundInverse)
                    Text(
                        text = stringResource(R.string.shelf_remove_from_named, shelfName),
                        style = RecitTheme.typography.action200,
                        color = RecitTheme.colors.foregroundInverse,
                    )
                }
            }
        },
    ) {
        InventoryItemRowWithActions(
            row = row,
            showsOwner = false,
            onClick = onOpen,
            onPush = onPush,
            modifier = Modifier.background(RecitTheme.colors.backgroundGroupedCell),
        )
    }
}

/** Deprecated constructor on purpose: removal needs half the width and a fling short of it is refused, which the current one cannot do. */
@Composable
private fun rememberDeliberateDismissState(): SwipeToDismissBoxState {
    val density: Density = LocalDensity.current
    return remember(density) {
        lateinit var state: SwipeToDismissBoxState
        state = SwipeToDismissBoxState(
            initialValue = SwipeToDismissBoxValue.Settled,
            density = density,
            confirmValueChange = { value -> value != SwipeToDismissBoxValue.EndToStart || state.targetValue == value },
            positionalThreshold = { distance -> distance / 2 },
        )
        state
    }
}
