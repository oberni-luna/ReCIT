package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ShelfEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.CapsuleTab
import studio.lunabee.nouveaurecit.ui.common.CapsuleTabs
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `ShelfDetailView` (`.shelf(id)`, iOS feature 0089): the étagère's name in the bar, then « Livres • N » |
 * « Présentation », changed by a touch on the capsule or a swipe — the pattern of a list's screen. On my
 * étagères the pencil opens the form (the screen pops if the étagère is deleted there), a swipe takes a book
 * off, and « Ajouter des livres » is pinned under « Livres ». A friend's étagère is the same screen, read-only.
 * Pushed from the Inventaire, it has no tab bar: the pinned button takes the bottom.
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
                containerColor = RecitTheme.colors.backgroundGrouped,
                actions = {
                    if (state.isMine) {
                        IconButton(onClick = { isEditing = true }) {
                            Icon(Icons.Default.Edit, contentDescription = stringResource(R.string.shelf_detail_edit))
                        }
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundGrouped,
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            val shelf: ShelfEntity? = state.shelf?.shelf
            if (state.isLoaded && shelf != null) {
                ShelfDetailPages(
                    shelf = shelf,
                    state = state,
                    onPush = navigator::push,
                    onRemove = viewModel::remove,
                    onAddBooks = { isAddingBooks = true },
                )
            }
        }
    }

    if (isAddingBooks) {
        ShelfAddBooksSheet(shelfId = destination.id, shelfName = shelfName, onDismiss = { isAddingBooks = false })
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

/**
 * `ShelfDetailView`'s `TabPager`: the capsule pinned under the bar, over two pages side by side, each keeping its
 * own scroll. The pinned button belongs to « Livres » and slides with it.
 */
@Composable
private fun ShelfDetailPages(
    shelf: ShelfEntity,
    state: ShelfViewModel.State,
    onPush: (Destination) -> Unit,
    onRemove: (String) -> Unit,
    onAddBooks: () -> Unit,
) {
    val pagerState: PagerState = rememberPagerState { ShelfDetailTab.entries.size }
    Column(Modifier.fillMaxSize()) {
        CapsuleTabs(
            tabs = shelfDetailTabs(state.books.size),
            pagerState = pagerState,
            modifier = Modifier
                .align(Alignment.CenterHorizontally)
                .padding(top = Spacing.xxSmall, bottom = Spacing.small),
        )
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f),
            verticalAlignment = Alignment.Top,
        ) { page ->
            when (ShelfDetailTab.entries[page]) {
                ShelfDetailTab.Books -> ShelfBooksPage(
                    books = state.books,
                    shelfName = shelf.name,
                    onPush = onPush,
                    onRemove = if (state.isMine) onRemove else null,
                    onAddBooks = if (state.isMine) onAddBooks else null,
                )
                ShelfDetailTab.Presentation -> ShelfPresentationPage(shelf)
            }
        }
    }
}

/** `ShelfDetailTabPicker`'s words: « Livres • 8 », then « Présentation ». */
@Composable
private fun shelfDetailTabs(count: Int): List<CapsuleTab> = ShelfDetailTab.entries.map { tab ->
    when (tab) {
        ShelfDetailTab.Books -> CapsuleTab(stringResource(R.string.shelf_tab_books, count), stringResource(R.string.shelf_tab_books_description, count))
        ShelfDetailTab.Presentation -> CapsuleTab(stringResource(R.string.shelf_tab_presentation))
    }
}
