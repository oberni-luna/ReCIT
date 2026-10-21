package studio.lunabee.nouveaurecit.ui.search

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
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
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingPlaceholder
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.LocalTabRouter
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.TabRouter

/**
 * The Recherche tab — `SearchTabView` (features 0037, 0040). Its field is always there, under the
 * title, and the keyboard stays down on arriving: the tab has something to show before anything is
 * typed. It comes up when the [TabRouter] asks — a second tap on the tab, or the empty shelf's
 * « Rechercher ».
 *
 * A collapsed Material 3 `SearchBar` is the field; what it answers is drawn under it by
 * [SearchContent], not in the bar's expanded surface.
 */
@Composable
fun SearchScreen(navigator: Navigator) {
    val viewModel: SearchViewModel = recitViewModel { SearchViewModel(it) }
    val router: TabRouter = LocalTabRouter.current
    val myUser: UserEntity? by viewModel.myUser.collectAsStateWithLifecycle()
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val focusManager: FocusManager = LocalFocusManager.current
    val focusRequester: FocusRequester = remember { FocusRequester() }
    val user: UserEntity? = myUser

    // On appearing as well as on change: the first request is usually the one that builds the tab.
    LaunchedEffect(router.wantsSearchField, user != null) {
        if (user != null && router.consumeSearchField()) runCatching { focusRequester.requestFocus() }
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = { RecitLargeTopBar(title = stringResource(R.string.tab_search), scrollBehavior = scrollBehavior) },
        containerColor = RecitTheme.colors.backgroundSecondary,
        contentWindowInsets = WindowInsets(0),
    ) { padding ->
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
                        expanded = false,
                        onExpandedChange = {},
                        modifier = Modifier.focusRequester(focusRequester),
                        placeholder = { Text(stringResource(R.string.inventory_search_placeholder)) },
                        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                        trailingIcon = {
                            if (viewModel.query.isNotEmpty()) {
                                IconButton(onClick = { viewModel.onQueryChange("") }) {
                                    Icon(Icons.Default.Close, contentDescription = stringResource(R.string.inventory_search_recents_clear))
                                }
                            }
                        },
                    )
                },
                expanded = false,
                onExpandedChange = {},
                modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium),
                colors = SearchBarDefaults.colors(containerColor = RecitTheme.colors.backgroundDefault),
            ) {}
            SearchSurface(viewModel = viewModel, myUserId = user.id, router = router, navigator = navigator)
        }
    }
}

@Composable
private fun SearchSurface(viewModel: SearchViewModel, myUserId: String, router: TabRouter, navigator: Navigator) {
    val recents: List<String> by viewModel.recents.collectAsStateWithLifecycle()
    val allItems: List<ItemRow> by viewModel.allItems.collectAsStateWithLifecycle()
    val friendsItems: List<ItemRow> by viewModel.friendsItems.collectAsStateWithLifecycle()
    val hasFriends: Boolean? by viewModel.hasFriends.collectAsStateWithLifecycle()
    val remoteState: RemoteSearchState by viewModel.remoteState.collectAsStateWithLifecycle()
    val focusManager: FocusManager = LocalFocusManager.current
    val phase: SearchPhase = viewModel.phase
    val friends: FriendsCarouselState = hasFriends?.let { FriendsCarouselState.current(phase, it, friendsItems.size) }
        ?: FriendsCarouselState.Hidden
    SearchContent(
        phase = phase,
        recents = recents,
        allItems = allItems,
        myUserId = myUserId,
        friends = friends,
        friendsItems = friendsItems,
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
        onInvite = router::openNetwork,
        onPush = navigator::push,
    )
}
