package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingPlaceholder
import studio.lunabee.nouveaurecit.ui.common.InventoryItemRow
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
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
 * shelf's « Rechercher » sends there. The scan and sort toolbar actions are not part of this port.
 */
@Composable
fun InventoryScreen(navigator: Navigator) {
    val viewModel: InventoryViewModel = recitViewModel { InventoryViewModel(it) }
    val router: TabRouter = LocalTabRouter.current
    val myUser: UserEntity? by viewModel.myUser.collectAsStateWithLifecycle()
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            RecitLargeTopBar(
                title = stringResource(R.string.tab_inventory),
                scrollBehavior = scrollBehavior,
                navigationIcon = { ProfileAvatarButton() },
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
            InventoryContent(viewModel = viewModel, navigator = navigator, onSearch = router::openSearch)
        }
    }
}

@Composable
private fun InventoryContent(viewModel: InventoryViewModel, navigator: Navigator, onSearch: () -> Unit) {
    val shelves: List<ShelfWithItems>? by viewModel.shelves.collectAsStateWithLifecycle()
    val myItems: List<ItemRow>? by viewModel.myItems.collectAsStateWithLifecycle()
    val syncState: FirstSyncState by viewModel.syncState.collectAsStateWithLifecycle()
    val isRefreshing: Boolean by viewModel.isRefreshing.collectAsStateWithLifecycle()
    var isCreatingShelf: Boolean by rememberSaveable { mutableStateOf(false) }
    val items: List<ItemRow> = myItems.orEmpty()

    PullToRefreshBox(isRefreshing = isRefreshing, onRefresh = viewModel::refresh, modifier = Modifier.fillMaxSize()) {
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
                        item(key = "shelves.empty") { EmptyShelfCard(ownsBooks = items.isNotEmpty(), onSearch = onSearch) }
                    }
                } else {
                    item(key = "shelves.carousel") {
                        ShelfCarousel(
                            shelves = loaded,
                            onOpenShelf = { navigator.push(Destination.Shelf(it)) },
                            onOpenItem = { navigator.push(Destination.Book(BookAnchor.Item(it))) },
                        )
                    }
                }
            }
            item(key = "books.header") {
                ShelvesSectionHeader(
                    title = stringResource(R.string.shelves_all_books, items.size),
                    modifier = Modifier.padding(top = Spacing.large),
                )
            }
            items(items, key = { it.item.id }) { row ->
                InventoryItemRow(
                    row = row,
                    showsOwner = false,
                    onClick = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) },
                )
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
        }
    }

    if (isCreatingShelf) {
        ShelfFormSheet(shelfId = null, fileItemId = null, onDismiss = { isCreatingShelf = false })
    }
}
