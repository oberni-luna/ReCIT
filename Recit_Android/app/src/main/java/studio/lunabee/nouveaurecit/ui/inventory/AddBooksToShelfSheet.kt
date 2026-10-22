package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.BookRow
import studio.lunabee.nouveaurecit.ui.common.recitViewModel

/** My copies, and which of them already stand on [shelfId]. */
@OptIn(ExperimentalCoroutinesApi::class)
class AddBooksToShelfViewModel(private val container: AppContainer, private val shelfId: String) : ViewModel() {
    data class Entry(val row: ItemRow, val isOnShelf: Boolean)

    val entries: StateFlow<List<Entry>?> = combine(
        container.users.myUserId.flatMapLatest { id -> id?.let(container.inventory::observeItemsOf) ?: flowOf(null) },
        container.shelves.observeShelf(shelfId),
    ) { items, shelf ->
        val onShelf: Set<String> = shelf?.items.orEmpty().map { it.item.id }.toSet()
        items?.map { Entry(it, it.item.id in onShelf) }
    }.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** Optimistic both ways, as the book's « … » menu is. */
    fun toggle(entry: Entry) {
        viewModelScope.launch {
            if (entry.isOnShelf) container.shelves.removeItem(shelfId, entry.row.item.id) else container.shelves.addItem(shelfId, entry.row.item.id)
        }
    }
}

/**
 * Filling an étagère from the étagère: my copies, one tap to put a book on it or take it off.
 * Before this, the only way in was a book's « … » menu, one book at a time.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddBooksToShelfSheet(shelfId: String, shelfName: String, onDismiss: () -> Unit) {
    val viewModel: AddBooksToShelfViewModel = recitViewModel(key = "add-books:$shelfId") { AddBooksToShelfViewModel(it, shelfId) }
    val entries: List<AddBooksToShelfViewModel.Entry>? by viewModel.entries.collectAsStateWithLifecycle()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = RecitTheme.colors.backgroundRaised,
    ) {
        Column(Modifier.fillMaxWidth().navigationBarsPadding()) {
            SheetHeader(
                title = stringResource(R.string.shelf_add_books_title, shelfName),
                closeLabel = stringResource(R.string.action_close),
                onClose = onDismiss,
                modifier = Modifier.padding(start = Spacing.medium, end = Spacing.xSmall),
            )
            val loaded: List<AddBooksToShelfViewModel.Entry> = entries.orEmpty()
            if (entries != null && loaded.isEmpty()) {
                EmptyState(
                    title = stringResource(R.string.shelf_add_books_empty_title),
                    message = stringResource(R.string.shelf_add_books_empty_message),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            LazyColumn {
                items(loaded, key = { it.row.item.id }) { entry ->
                    BookRow(
                        title = entry.row.title,
                        imageUrl = entry.row.image,
                        onClick = { viewModel.toggle(entry) },
                        authors = entry.row.authorNames.joinToString(", "),
                        trailing = {
                            Icon(
                                imageVector = if (entry.isOnShelf) Icons.Filled.CheckCircle else Icons.Filled.AddCircleOutline,
                                contentDescription = stringResource(
                                    if (entry.isOnShelf) R.string.shelf_add_books_on_shelf else R.string.shelf_add_books_add,
                                ),
                                tint = if (entry.isOnShelf) RecitTheme.colors.foregroundTinted else RecitTheme.colors.foregroundSecondary,
                            )
                        },
                    )
                    HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
                }
            }
        }
    }
}
