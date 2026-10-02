package studio.lunabee.nouveaurecit.ui.network

import android.content.Context
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingInlineRow
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitLargeTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

class NetworkViewModel(private val container: AppContainer) : ViewModel() {
    val invitations: StateFlow<List<UserEntity>> = container.users.observeByRelation(UserRelation.RequestReceived)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val friends: StateFlow<List<UserEntity>> = container.users.observeByRelation(UserRelation.Friend)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val communityState: StateFlow<SyncStatus.State?> = container.syncStatus.domains
        .map { it[SyncStatus.Domain.Community] }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    /** Each friend's first-sync state, keyed by id — the bar under their name. */
    val syncStates: StateFlow<Map<String, FirstSyncState>> =
        combine(friends, invitations, container.syncStatus.firstSyncProgress) { friends, invitations, progress ->
            (friends + invitations).associate { it.id to FirstSyncState.of(it.lastInventorySync, progress[it.id]) }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    val actions: RelationActions = RelationActions(container, viewModelScope)

    suspend fun refresh() = container.session.refresh()
}

/**
 * `NetworkView` with its `FriendsSegmentView` — Réseau › Amis. The invitations waiting on me come
 * first (inventaire.io notifies nobody, so the app is where they are found), then my friends and
 * the way to add more. The Groupes segment is not ported, so there is no segmented control.
 */
@Composable
fun NetworkScreen(navigator: Navigator) {
    val viewModel: NetworkViewModel = recitViewModel { NetworkViewModel(it) }
    val invitations: List<UserEntity> by viewModel.invitations.collectAsStateWithLifecycle()
    val friends: List<UserEntity> by viewModel.friends.collectAsStateWithLifecycle()
    val community: SyncStatus.State? by viewModel.communityState.collectAsStateWithLifecycle()
    val syncStates: Map<String, FirstSyncState> by viewModel.syncStates.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val sectionState: FriendsSectionState = friendsSectionState(community, friends.size)
    var isRefreshing: Boolean by remember { mutableStateOf(false) }
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            RecitLargeTopBar(title = stringResource(R.string.network_nav_network), scrollBehavior = scrollBehavior) {
                IconButton(onClick = { navigator.push(Destination.AddFriends) }) {
                    Icon(Icons.Rounded.Add, contentDescription = stringResource(R.string.network_add_friends))
                }
            }
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = isRefreshing,
            onRefresh = {
                scope.launch {
                    isRefreshing = true
                    try {
                        viewModel.refresh()
                    } finally {
                        isRefreshing = false
                    }
                }
            },
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = Spacing.large),
            ) {
                if (invitations.isNotEmpty()) {
                    item(key = "invitations-header") {
                        SectionHeader(stringResource(R.string.network_profile_invitations), Modifier.padding(horizontal = Spacing.medium))
                    }
                    item(key = "invitations") {
                        SectionCard {
                            invitations.forEach { user ->
                                InvitationRow(
                                    user = user,
                                    syncState = syncStates[user.id] ?: FirstSyncState.Synced,
                                    onOpen = { navigator.push(Destination.User(user.id)) },
                                    onAccept = {
                                        viewModel.actions.accept(user.id)
                                        messenger.show(context.getString(R.string.network_invitation_accepted, user.username))
                                    },
                                    onRefuse = {
                                        viewModel.actions.refuse(user.id)
                                        messenger.show(context.getString(R.string.network_invitation_refused, user.username))
                                    },
                                )
                                HorizontalDivider(color = RecitTheme.colors.borderDefault)
                            }
                            LinkRow(stringResource(R.string.network_invitations_all)) { navigator.push(Destination.Invitations) }
                        }
                    }
                }

                item(key = "friends-header") {
                    SectionHeader(stringResource(R.string.network_friends), Modifier.padding(horizontal = Spacing.medium))
                }
                item(key = "friends") {
                    SectionCard {
                        when (sectionState) {
                            FriendsSectionState.Syncing -> SyncingInlineRow(
                                message = stringResource(R.string.sync_loading),
                                modifier = Modifier.padding(horizontal = Spacing.medium),
                            )
                            FriendsSectionState.Empty -> PlainRow(stringResource(R.string.network_profile_network_empty))
                            FriendsSectionState.Friends -> friends.forEach { friend ->
                                ReaderCell(
                                    user = friend,
                                    syncState = syncStates[friend.id] ?: FirstSyncState.Synced,
                                    onClick = { navigator.push(Destination.User(friend.id)) },
                                )
                                HorizontalDivider(color = RecitTheme.colors.borderDefault)
                            }
                        }
                        // Present even with no friend at all: an empty network is when one needs it.
                        if (sectionState != FriendsSectionState.Syncing) {
                            LinkRow(stringResource(R.string.network_add_friends)) { navigator.push(Destination.AddFriends) }
                        }
                    }
                }
            }
        }
    }
}
