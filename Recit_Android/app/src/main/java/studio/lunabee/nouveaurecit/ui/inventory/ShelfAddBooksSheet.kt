package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitSearchField
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.BookRow
import studio.lunabee.nouveaurecit.ui.common.recitViewModel

/**
 * `ShelfAddBooksSheet` (iOS feature 0089), opened by « Ajouter des livres »: every book of mine not on the
 * étagère yet, newest first, a checkbox each, the whole row ticking it; a search field « Titre ou auteur·ice »
 * always there; « Ajouter N livres » pinned at the foot, disabled at 0. The button files the ticked books in
 * one optimistic `add-items` and closes the sheet: they are on the étagère behind it at once. No removal here:
 * removal is the swipe on the étagère's page. What shows and what is added: [ShelfAddBooksSelection].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShelfAddBooksSheet(shelfId: String, shelfName: String, onDismiss: () -> Unit) {
    val viewModel: ShelfAddBooksViewModel = recitViewModel(key = "shelf-add-books:$shelfId") { ShelfAddBooksViewModel(it, shelfId) }
    val books: ShelfAddBooksViewModel.Books? by viewModel.books.collectAsStateWithLifecycle()
    var query: String by rememberSaveable { mutableStateOf("") }
    // By server id: an id survives a sync replacing the copy under it.
    var ticked: List<String> by rememberSaveable { mutableStateOf(emptyList()) }
    val selection: ShelfAddBooksSelection = remember(books, ticked, query) {
        ShelfAddBooksSelection(
            myBooks = books?.mine.orEmpty(),
            onShelf = books?.onShelf.orEmpty(),
            ticked = ticked.toSet(),
            query = query,
        )
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = RecitTheme.colors.backgroundRaised,
    ) {
        Column(Modifier.fillMaxSize().navigationBarsPadding().imePadding()) {
            SheetHeader(
                title = stringResource(R.string.shelf_add_books_title, shelfName),
                closeLabel = stringResource(R.string.action_close),
                onClose = onDismiss,
                modifier = Modifier.padding(start = Spacing.medium, end = Spacing.xSmall),
            )
            RecitSearchField(
                query = query,
                onQueryChange = { query = it },
                placeholder = stringResource(R.string.shelf_add_books_search_prompt),
                clearLabel = stringResource(R.string.shelf_add_books_search_clear),
                autoCorrect = false,
                modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
            )
            Box(Modifier.weight(1f).fillMaxWidth()) {
                if (books != null) {
                    ShelfAddBooksContent(
                        selection = selection,
                        onToggle = { id -> ticked = selection.toggling(id).ticked.toList() },
                        modifier = Modifier.align(Alignment.TopCenter),
                    )
                }
            }
            ShelfPinnedButton(
                text = pluralStringResource(R.plurals.shelf_add_books_submit, selection.count, selection.count),
                onClick = {
                    viewModel.add(selection.toAdd)
                    onDismiss()
                },
                background = RecitTheme.colors.backgroundRaised,
                enabled = selection.canAdd,
            )
        }
    }
}

/** The rows, or the one sentence that stands in for them. */
@Composable
private fun ShelfAddBooksContent(selection: ShelfAddBooksSelection, onToggle: (String) -> Unit, modifier: Modifier = Modifier) {
    when (selection.emptiness) {
        ShelfAddBooksSelection.Emptiness.NoBook -> EmptyState(
            title = stringResource(R.string.shelf_add_books_no_books),
            icon = Icons.AutoMirrored.Filled.LibraryBooks,
            modifier = modifier.fillMaxWidth(),
        )
        ShelfAddBooksSelection.Emptiness.AllOnShelf -> EmptyState(
            title = stringResource(R.string.shelf_add_books_all_on_shelf),
            modifier = modifier.fillMaxWidth(),
        )
        ShelfAddBooksSelection.Emptiness.NoMatch -> EmptyState(
            title = stringResource(R.string.shelf_add_books_search_empty, selection.trimmedQuery),
            icon = Icons.Default.Search,
            modifier = modifier.fillMaxWidth(),
        )
        null -> LazyColumn(modifier.fillMaxSize()) {
            items(selection.visible, key = { it.item.id }) { row ->
                ShelfAddBookRow(row = row, isTicked = selection.isTicked(row.item.id), onToggle = { onToggle(row.item.id) })
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
        }
    }
}

/** `ShelfAddBookRow`: one of my books, the check after it, the whole row toggling it. */
@Composable
private fun ShelfAddBookRow(row: ItemRow, isTicked: Boolean, onToggle: () -> Unit) {
    BookRow(
        title = row.title,
        imageUrl = row.image,
        onClick = onToggle,
        authors = row.authorNames.joinToString(", "),
        modifier = Modifier.semantics { selected = isTicked },
        trailing = {
            Icon(
                imageVector = if (isTicked) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
                contentDescription = null,
                tint = if (isTicked) RecitTheme.colors.foregroundTinted else RecitTheme.colors.foregroundSecondary,
            )
        },
    )
}
