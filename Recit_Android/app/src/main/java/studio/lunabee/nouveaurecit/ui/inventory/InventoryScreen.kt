package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingPlaceholder
import studio.lunabee.nouveaurecit.ui.book.InventoryItemRowWithActions
import studio.lunabee.nouveaurecit.ui.common.LargeTitleRefreshBox
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.flow.LocalSortFlow
import studio.lunabee.nouveaurecit.ui.flow.SortFlowPresentation
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.LocalTabRouter
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.TabRouter
import studio.lunabee.nouveaurecit.ui.profile.ProfileAvatarButton

/**
 * The Inventaire tab — `ShelvesView` / `ShelvesContent` (features 0001, 0005, 0021, 0027).
 *
 * My first-sync banner, « Étagères » with « Ajouter », the shelf carousel (or the empty-shelf card),
 * then « Tous les livres · N ». The search left for a tab of its own (feature 0037); the empty
 * shelf's « Rechercher » sends there. « Ranger » (once the inventory has synced) and « Scanner » in
 * the toolbar open the scan-and-sort flow at the surface or at the camera (ADR 0007).
 */
@Composable
fun InventoryScreen(navigator: Navigator) {
    val viewModel: InventoryViewModel = recitViewModel { InventoryViewModel(it) }
    val router: TabRouter = LocalTabRouter.current
    val sortFlow: SortFlowPresentation = LocalSortFlow.current
    val myUser: UserEntity? by viewModel.myUser.collectAsStateWithLifecycle()
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    Scaffold(
        topBar = {
            RecitLargeTopBar(
                title = stringResource(R.string.tab_inventory),
                scrollBehavior = scrollBehavior,
                navigationIcon = { ProfileAvatarButton() },
                actions = {
                    if (myUser?.lastInventorySync != null) {
                        ToolbarAction(
                            title = stringResource(R.string.shelves_action_sort),
                            icon = Icons.AutoMirrored.Filled.LibraryBooks,
                            onClick = sortFlow::presentSorting,
                        )
                    }
                    ToolbarAction(
                        title = stringResource(R.string.shelves_action_scan),
                        icon = Icons.Default.QrCodeScanner,
                        onClick = sortFlow::presentScanning,
                    )
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundDefault,
        contentWindowInsets = WindowInsets(0),
    ) { padding ->
        if (myUser == null) {
            SyncingPlaceholder(message = stringResource(R.string.sync_loading), modifier = Modifier.padding(padding))
            return@Scaffold
        }
        Box(Modifier.fillMaxSize().padding(padding)) {
            InventoryContent(
                viewModel = viewModel,
                navigator = navigator,
                scrollBehavior = scrollBehavior,
                onScan = sortFlow::presentScanning,
                onSort = sortFlow::presentSorting,
                onSearch = router::openSearch,
            )
        }
    }
}

@Composable
private fun InventoryContent(
    viewModel: InventoryViewModel,
    navigator: Navigator,
    scrollBehavior: TopAppBarScrollBehavior,
    onScan: () -> Unit,
    onSort: () -> Unit,
    onSearch: () -> Unit,
) {
    val shelves: List<ShelfWithItems>? by viewModel.shelves.collectAsStateWithLifecycle()
    val myItems: List<ItemRow>? by viewModel.myItems.collectAsStateWithLifecycle()
    val syncState: FirstSyncState by viewModel.syncState.collectAsStateWithLifecycle()
    val isRefreshing: Boolean by viewModel.isRefreshing.collectAsStateWithLifecycle()
    var isCreatingShelf: Boolean by rememberSaveable { mutableStateOf(false) }
    var addingBooksTo: ShelfWithItems? by remember { mutableStateOf(null) }
    val items: List<ItemRow> = myItems.orEmpty()

    LargeTitleRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = viewModel::refresh,
        scrollBehavior = scrollBehavior,
        modifier = Modifier.fillMaxSize(),
    ) {
        LazyColumn(Modifier.fillMaxSize()) {
            if (syncState != FirstSyncState.Synced) {
                item(key = "syncBanner") {
                    InventorySyncBanner(
                        state = syncState,
                        modifier = Modifier.padding(horizontal = Spacing.medium).padding(top = Spacing.small),
                    )
                }
            }
            item(key = "shelves.header") {
                ShelvesSectionHeader(
                    title = stringResource(R.string.shelves_section_title),
                    actionTitle = stringResource(R.string.shelves_section_add),
                    onAction = { isCreatingShelf = true },
                    modifier = Modifier.padding(top = Spacing.medium),
                )
            }
            val loaded: List<ShelfWithItems>? = shelves
            if (loaded != null) {
                if (loaded.isEmpty()) {
                    if (syncState == FirstSyncState.Synced && myItems != null) {
                        item(key = "shelves.empty") { EmptyShelfCard(ownsBooks = items.isNotEmpty(), onScan = onScan, onSearch = onSearch, onSort = onSort) }
                    }
                } else {
                    item(key = "shelves.carousel") {
                        ShelfCarousel(
                            shelves = loaded,
                            onOpenShelf = { navigator.push(Destination.Shelf(it)) },
                            onOpenItem = { navigator.push(Destination.Book(BookAnchor.Item(it))) },
                            onAddBooks = { addingBooksTo = it },
                        )
                    }
                }
            }
            // No count until the store has answered: « Tous les livres · 0 » would flash on launch.
            if (myItems != null) {
                item(key = "books.header") {
                    ShelvesSectionHeader(
                        title = stringResource(R.string.shelves_all_books, items.size),
                        modifier = Modifier.padding(top = Spacing.large),
                    )
                }
            }
            items(items, key = { it.item.id }) { row ->
                InventoryItemRowWithActions(
                    row = row,
                    showsOwner = false,
                    onClick = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) },
                    onPush = navigator::push,
                )
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
        }
    }

    if (isCreatingShelf) {
        ShelfFormSheet(shelfId = null, fileItemId = null, onDismiss = { isCreatingShelf = false })
    }
    addingBooksTo?.let { shelf ->
        AddBooksToShelfSheet(shelfId = shelf.shelf.id, shelfName = shelf.shelf.name, onDismiss = { addingBooksTo = null })
    }
}

/** A toolbar button with its glyph *and* its word, as `Button(_:systemImage:)` draws in a toolbar. */
@Composable
private fun ToolbarAction(title: String, icon: ImageVector, onClick: () -> Unit) {
    TextButton(onClick = onClick) {
        Icon(icon, contentDescription = null, tint = RecitTheme.colors.foregroundTinted, modifier = Modifier.size(18.dp))
        Text(
            text = title,
            style = RecitTheme.typography.action300,
            color = RecitTheme.colors.foregroundTinted,
            modifier = Modifier.padding(start = Spacing.xSmall),
        )
    }
}
