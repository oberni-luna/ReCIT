package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.outlined.Outbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
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
    val shelfName: String = state.shelf?.shelf?.name.orEmpty()

    Scaffold(
        topBar = {
            RecitTopBar(
                title = shelfName,
                onBack = navigator::pop,
                actions = {
                    if (state.isMine) {
                        TextButton(onClick = { isEditing = true }) {
                            Icon(Icons.Default.Edit, contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.size(18.dp))
                            Text(
                                text = stringResource(R.string.shelf_detail_edit),
                                style = RecitTheme.typography.action300,
                                color = RecitTheme.colors.foregroundTinted,
                                modifier = Modifier.padding(start = Spacing.xSmall),
                            )
                        }
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding)) {
            if (state.isLoaded && state.books.isEmpty()) {
                item(key = "empty") {
                    Text(
                        text = stringResource(R.string.shelf_detail_empty),
                        style = RecitTheme.typography.action200,
                        color = RecitTheme.colors.foregroundSecondary,
                        modifier = Modifier.padding(Spacing.medium),
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

    if (isEditing) {
        ShelfFormSheet(
            shelfId = destination.id,
            fileItemId = null,
            onDismiss = { isEditing = false },
            onDeleted = navigator::pop,
        )
    }
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
