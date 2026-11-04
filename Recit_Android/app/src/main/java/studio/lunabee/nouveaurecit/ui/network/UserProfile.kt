package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.ui.common.CapsuleTab
import studio.lunabee.nouveaurecit.ui.lists.ListRowModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `UserDetailView` + `UserProfilePager` (iOS features 0064, 0066, 0067), shaped like the Contacts card of
 * Messages: the header over pages side by side, each scrolling on its own — Inventaire, Listes,
 * Présentation for a friend or for me, one page for anyone else. A swipe turns the page and the capsule
 * follows the finger; the header folds by the page on screen, blended between two pages mid-swipe.
 */
@Composable
internal fun UserProfile(
    user: UserEntity,
    isMe: Boolean,
    showsTabs: Boolean,
    viewModel: UserViewModel,
    navigator: Navigator,
    onAskToAdd: () -> Unit,
    bottomPadding: Dp,
) {
    val pageCount: Int = if (showsTabs) UserProfileTab.entries.size else 1
    val pagerState: PagerState = rememberPagerState { pageCount }
    val pageStates: List<LazyListState> = List(pageCount) { index -> key(index) { rememberLazyListState() } }
    val metrics: UserProfileHeaderMetrics = rememberUserProfileHeaderMetrics()
    val density: Density = LocalDensity.current
    val distance: Float = with(density) { metrics.foldDistance.toPx() }
    val collapse: ProfileHeaderCollapse = remember(distance) { ProfileHeaderCollapse(distance) }
    val position: () -> Float = { pagerState.currentPage + pagerState.currentPageOffsetFraction }
    val progress: State<Float> = remember(collapse, pageStates) {
        derivedStateOf { collapse.progress(pageStates.map { it.headerOffset() }, position()) }
    }
    val backdrop: State<Float> = remember(collapse, pageStates) {
        derivedStateOf {
            ProfileHeaderCollapse.blend(pageStates.map { if (collapse.isContentUnder(it.headerOffset())) 1f else 0f }, position())
        }
    }
    val items: List<ItemRow> by viewModel.items.collectAsStateWithLifecycle()
    val shelves: List<ShelfWithItems> by viewModel.shelves.collectAsStateWithLifecycle()
    val localCount: Int by viewModel.localItemCount.collectAsStateWithLifecycle()
    val syncProgress: Map<String, SyncStatus.Progress> by viewModel.firstSyncProgress.collectAsStateWithLifecycle()
    val lists: List<ListRowModel> by viewModel.lists.collectAsStateWithLifecycle()
    val listsLoad: UserListsLoad by viewModel.listsLoad.collectAsStateWithLifecycle()
    val syncState: FirstSyncState = FirstSyncState.of(user.lastInventorySync, syncProgress[user.id])
    // Mine is synced whole and kept in step locally; anyone else's count is the server's snapshot.
    val itemCount: Int = if (isMe && user.lastInventorySync != null) localCount else user.itemCount
    var expandedHeaderHeight: Int by remember { mutableIntStateOf(0) }
    val headerRoom: Dp = with(density) { expandedHeaderHeight.toDp() }.coerceAtLeast(metrics.topExpanded)

    Box(Modifier.fillMaxSize()) {
        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            UserProfilePage(
                state = pageStates[page],
                collapse = collapse,
                headerRoom = headerRoom,
                bottomPadding = bottomPadding,
            ) {
                when {
                    !showsTabs -> userClosedItems(user = user, actions = viewModel.actions, onAskToAdd = onAskToAdd)
                    else -> when (UserProfileTab.entries[page]) {
                        UserProfileTab.Inventory -> userInventoryItems(user, shelves, items, syncState, navigator)
                        UserProfileTab.Lists -> userListsItems(user, lists, listsLoad) { navigator.push(Destination.EntityList(it)) }
                        UserProfileTab.Presentation -> userPresentationItems(user)
                    }
                }
            }
        }
        UserProfileHeader(
            user = user,
            progress = { progress.value },
            backdrop = { backdrop.value },
            metrics = metrics,
            tabs = if (showsTabs) userProfileTabs(itemCount, lists.size, listsLoad) else null,
            pagerState = pagerState,
            // The header's height at rest, whatever the fold it was measured at: folding takes the fold's
            // whole distance off it, its top rising and its picture and name shrinking.
            onHeightChange = { height -> expandedHeaderHeight = (height + distance * progress.value).toInt() },
        )
    }
}

/** `UserProfileTabLabel`: « Inventaire • 540 », « Listes • 4 » — « Listes » alone while the first fetch runs with nothing stored — and « Présentation ». */
@Composable
private fun userProfileTabs(itemCount: Int, listCount: Int, listsLoad: UserListsLoad): List<CapsuleTab> = UserProfileTab.entries.map { tab ->
    when (tab) {
        UserProfileTab.Inventory -> CapsuleTab(
            label = stringResource(R.string.network_user_tab_inventory, itemCount),
            description = pluralStringResource(R.plurals.network_user_tab_inventory_description, itemCount, itemCount),
        )
        UserProfileTab.Lists -> if (listCount == 0 && listsLoad == UserListsLoad.Loading) {
            CapsuleTab(stringResource(R.string.network_user_tab_lists_loading))
        } else {
            CapsuleTab(
                label = stringResource(R.string.network_user_tab_lists, listCount),
                description = stringResource(R.string.network_user_tab_lists_description, listCount),
            )
        }
        UserProfileTab.Presentation -> CapsuleTab(stringResource(R.string.network_user_tab_presentation))
    }
}
