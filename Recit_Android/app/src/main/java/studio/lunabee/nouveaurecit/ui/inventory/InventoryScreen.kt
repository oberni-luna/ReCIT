package studio.lunabee.nouveaurecit.ui.inventory

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalFocusManager
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
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * The Inventaire tab — `ShelvesView` / `ShelvesContent` and, while the search is up,
 * `InventorySearchContent` (features 0001, 0005, 0014, 0021, 0027).
 *
 * Not searching: my first-sync banner, « Étagères » with « Ajouter », the shelf carousel (or the
 * empty-shelf card), then « Tous les livres · N ». The Material 3 `SearchBar` stands in for
 * `.searchable`; expanded, it hosts the unified search. The scan and sort toolbar actions are not
 * part of this port.
 */
@Composable
fun InventoryScreen(navigator: Navigator) {
    val viewModel: InventoryViewModel = recitViewModel { InventoryViewModel(it) }
    val myUser: UserEntity? by viewModel.myUser.collectAsStateWithLifecycle()
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val focusManager: FocusManager = LocalFocusManager.current
    val focusRequester: FocusRequester = remember { FocusRequester() }
    var focusTick: Int by remember { mutableIntStateOf(0) }
    val expanded: Boolean = viewModel.expanded

    LaunchedEffect(focusTick) {
        if (focusTick > 0) runCatching { focusRequester.requestFocus() }
    }
    BackHandler(enabled = expanded) { viewModel.onExpandedChange(false) }

    Scaffold(
        modifier = if (expanded) Modifier else Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            if (!expanded) RecitLargeTopBar(title = stringResource(R.string.tab_inventory), scrollBehavior = scrollBehavior)
        },
        containerColor = RecitTheme.colors.backgroundDefault,
        contentWindowInsets = WindowInsets(0),
    ) { padding ->
        val user: UserEntity? = myUser
        if (user == null) {
            SyncingPlaceholder(message = stringResource(R.string.sync_loading), modifier = Modifier.padding(padding))
            return@Scaffold
        }
        Column(Modifier.fillMaxSize().padding(padding)) {
            SearchBar(
                inputField = {
                    SearchBarDefaults.InputField(
                        query = viewModel.query,
                        onQueryChange = viewModel::onQueryChange,
                        onSearch = {
                            viewModel.submitKeyboard()
                            focusManager.clearFocus()
                        },
                        expanded = expanded,
                        onExpandedChange = viewModel::onExpandedChange,
                        modifier = Modifier.focusRequester(focusRequester),
                        placeholder = { Text(stringResource(R.string.inventory_search_placeholder)) },
                        leadingIcon = {
                            if (expanded) {
                                IconButton(onClick = { viewModel.onExpandedChange(false) }) {
                                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back))
                                }
                            } else {
                                Icon(Icons.Default.Search, contentDescription = null)
                            }
                        },
                        trailingIcon = {
                            if (expanded && viewModel.query.isNotEmpty()) {
                                IconButton(onClick = { viewModel.onQueryChange("") }) {
                                    Icon(Icons.Default.Close, contentDescription = stringResource(R.string.inventory_search_recents_clear))
                                }
                            }
                        },
                    )
                },
                expanded = expanded,
                onExpandedChange = viewModel::onExpandedChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = if (expanded) Spacing.zero else Spacing.medium),
                colors = SearchBarDefaults.colors(containerColor = RecitTheme.colors.backgroundSecondary),
            ) {
                SearchSurface(viewModel = viewModel, myUserId = user.id, navigator = navigator)
            }
            if (!expanded) {
                InventoryContent(
                    viewModel = viewModel,
                    navigator = navigator,
                    onSearch = {
                        viewModel.onExpandedChange(true)
                        focusTick += 1
                    },
                )
            }
        }
    }
}

@Composable
private fun SearchSurface(viewModel: InventoryViewModel, myUserId: String, navigator: Navigator) {
    val recents: List<String> by viewModel.recents.collectAsStateWithLifecycle()
    val allItems: List<ItemRow> by viewModel.allItems.collectAsStateWithLifecycle()
    val remoteState: RemoteSearchState by viewModel.remoteState.collectAsStateWithLifecycle()
    val focusManager: FocusManager = LocalFocusManager.current
    InventorySearchContent(
        phase = viewModel.phase,
        recents = recents,
        allItems = allItems,
        myUserId = myUserId,
        remoteState = remoteState,
        onSelectRecent = { recent ->
            viewModel.selectRecent(recent)
            focusManager.clearFocus()
        },
        onClearRecents = viewModel::clearRecents,
        onSuggestion = { suggestion ->
            viewModel.submit(suggestion)
            focusManager.clearFocus()
        },
        onRetry = viewModel::retry,
        onPush = navigator::push,
    )
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
