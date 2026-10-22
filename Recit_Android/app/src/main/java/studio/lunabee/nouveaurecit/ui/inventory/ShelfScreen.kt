package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.outlined.Outbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TintedTextButton
import studio.lunabee.nouveaurecit.ui.common.InventoryItemRow
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `ShelfDetailView` (`.shelf(id)`): a shelf's copies, newest first. On my shelves, « Modifier »
 * opens the shelf form (the screen pops if the shelf is deleted there) and a swipe takes a copy off
 * the shelf. A friend's shelf is read-only.
 */
@Composable
fun ShelfScreen(destination: Destination.Shelf, navigator: Navigator) {
    val viewModel: ShelfViewModel = recitViewModel(key = "shelf:${destination.id}") { ShelfViewModel(it, destination.id) }
    val state: ShelfViewModel.State by viewModel.state.collectAsStateWithLifecycle()
    var isEditing: Boolean by rememberSaveable { mutableStateOf(false) }
    var isAddingBooks: Boolean by rememberSaveable { mutableStateOf(false) }
    val shelfName: String = state.shelf?.shelf?.name.orEmpty()

    Scaffold(
        topBar = {
            RecitTopBar(
                title = shelfName,
                onBack = navigator::pop,
                actions = {
                    if (state.isMine) {
                        IconButton(onClick = { isEditing = true }) {
                            Icon(Icons.Default.Edit, contentDescription = stringResource(R.string.shelf_detail_edit))
                        }
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        val shelf = state.shelf
        if (state.isLoaded && shelf != null && state.books.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                EmptyState(
                    title = stringResource(R.string.shelf_detail_empty),
                    message = if (state.isMine) stringResource(R.string.shelf_detail_empty_message) else null,
                    icon = Icons.AutoMirrored.Outlined.LibraryBooks,
                    actionTitle = if (state.isMine) stringResource(R.string.shelf_empty_action_add_title) else null,
                    onAction = { isAddingBooks = true },
                )
            }
            return@Scaffold
        }
        LazyColumn(Modifier.fillMaxSize().padding(padding)) {
            if (shelf != null) {
                item(key = "header") {
                    ShelfHeader(
                        description = shelf.shelf.description,
                        count = state.books.size,
                        visibility = ShelfVisibility.from(shelf.shelf.visibility),
                        onAddBooks = if (state.isMine) ({ isAddingBooks = true }) else null,
                    )
                }
            }
            items(state.books, key = { it.item.id }) { row ->
                val open: () -> Unit = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) }
                if (state.isMine) {
                    RemovableRow(row = row, shelfName = shelfName, onOpen = open, onRemove = { viewModel.remove(row.item.id) })
                } else {
                    InventoryItemRow(row = row, showsOwner = false, onClick = open)
                }
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
        }
    }

    if (isAddingBooks) {
        AddBooksToShelfSheet(shelfId = destination.id, shelfName = shelfName, onDismiss = { isAddingBooks = false })
    }
    if (isEditing) {
        ShelfFormSheet(
            shelfId = destination.id,
            fileItemId = null,
            onDismiss = { isEditing = false },
            onDeleted = navigator::pop,
        )
    }
}

/** What the étagère is: its description, how many books, who sees it, and — on mine — a way to fill it. */
@Composable
private fun ShelfHeader(description: String, count: Int, visibility: ShelfVisibility, onAddBooks: (() -> Unit)?) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium).padding(top = Spacing.small, bottom = Spacing.small),
        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        if (description.isNotBlank()) {
            Text(description, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = pluralStringResource(R.plurals.shelf_detail_count, count, count) + " · " + stringResource(visibilityLabel(visibility)),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                modifier = Modifier.weight(1f),
            )
            if (onAddBooks != null) {
                TintedTextButton(text = stringResource(R.string.shelf_empty_action_add_title), onClick = onAddBooks, icon = Icons.Default.Add)
            }
        }
    }
}

private fun visibilityLabel(visibility: ShelfVisibility): Int = when (visibility) {
    ShelfVisibility.Private -> R.string.shelf_detail_visibility_private
    ShelfVisibility.Friends -> R.string.shelf_detail_visibility_friends
    ShelfVisibility.Public -> R.string.shelf_detail_visibility_public
}

/** `.swipeActions(edge: .trailing, allowsFullSwipe: true)` — « Retirer de %@ ». */
@Composable
private fun RemovableRow(row: ItemRow, shelfName: String, onOpen: () -> Unit, onRemove: () -> Unit) {
    val dismissState: SwipeToDismissBoxState = rememberSwipeToDismissBoxState()
    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = false,
        onDismiss = { value -> if (value == SwipeToDismissBoxValue.EndToStart) onRemove() },
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(RecitTheme.colors.backgroundTintedInverse)
                    .padding(horizontal = Spacing.medium),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    Icon(Icons.Outlined.Outbox, contentDescription = null, tint = RecitTheme.colors.foregroundTintedInverse)
                    Text(
                        text = stringResource(R.string.shelf_remove_from_named, shelfName),
                        style = RecitTheme.typography.action200,
                        color = RecitTheme.colors.foregroundTintedInverse,
                    )
                }
            }
        },
    ) {
        InventoryItemRow(
            row = row,
            showsOwner = false,
            onClick = onOpen,
            modifier = Modifier.background(RecitTheme.colors.backgroundDefault),
        )
    }
}
