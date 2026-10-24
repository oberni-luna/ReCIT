package studio.lunabee.nouveaurecit.ui.network

import android.content.Context
import androidx.compose.foundation.layout.Column
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
import androidx.compose.runtime.saveable.rememberSaveable
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
import studio.lunabee.nouveaurecit.ui.network.groups.CreateGroupSheet
import studio.lunabee.nouveaurecit.ui.network.groups.GroupsSegment
import studio.lunabee.nouveaurecit.ui.profile.ProfileAvatarButton

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

    /** The segment the tab shows: the last one chosen, `null` until the preference is read. */
    val segment: StateFlow<NetworkSegment?> = container.preferences.observeString(NetworkSegment.STORAGE_KEY)
        .map(NetworkSegment::restored)
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    fun select(segment: NetworkSegment) {
        viewModelScope.launch { container.preferences.setString(NetworkSegment.STORAGE_KEY, segment.name) }
    }
}

/**
 * `NetworkView`: the Réseau tab, split by a segmented control fixed under the title — Amis, the
 * readers I am close to, and Groupes, inventaire.io's other way of sharing books (feature 0046).
 * The tab reopens on the segment chosen last.
 */
@Composable
fun NetworkScreen(navigator: Navigator) {
    val viewModel: NetworkViewModel = recitViewModel { NetworkViewModel(it) }
    val segment: NetworkSegment? by viewModel.segment.collectAsStateWithLifecycle()
    val scope: CoroutineScope = rememberCoroutineScope()
    var isRefreshing: Boolean by remember { mutableStateOf(false) }
    var isCreatingGroup: Boolean by rememberSaveable { mutableStateOf(false) }
    val scrollBehavior: TopAppBarScrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            Column {
                RecitLargeTopBar(
                    title = stringResource(R.string.network_nav_network),
                    scrollBehavior = scrollBehavior,
                    navigationIcon = { ProfileAvatarButton() },
                    containerColor = RecitTheme.colors.backgroundDefault,
                ) {
                    // The « + » follows the segment: a friend to find on one side, a group to start on the other.
                    when (segment) {
                        NetworkSegment.Friends -> IconButton(onClick = { navigator.push(Destination.AddFriends) }) {
                            Icon(Icons.Rounded.Add, contentDescription = stringResource(R.string.network_add_friends))
                        }
                        NetworkSegment.Groups -> IconButton(onClick = { isCreatingGroup = true }) {
                            Icon(Icons.Rounded.Add, contentDescription = stringResource(R.string.groups_create))
                        }
                        null -> Unit
                    }
                }
                NetworkSegmentBand(
                    selected = segment ?: NetworkSegment.Friends,
                    onSelect = viewModel::select,
                    collapsedFraction = scrollBehavior.state.collapsedFraction,
                )
            }
        },
        containerColor = RecitTheme.colors.backgroundDefault,
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
            when (segment) {
                NetworkSegment.Friends -> FriendsSegment(viewModel, navigator)
                NetworkSegment.Groups -> GroupsSegment(navigator, onCreate = { isCreatingGroup = true })
                null -> Unit
            }
        }
    }

    if (isCreatingGroup) {
        CreateGroupSheet(
            onDismiss = { isCreatingGroup = false },
            onCreated = { groupId -> navigator.push(Destination.Group(groupId)) },
        )
    }
}

/**
 * `FriendsSegmentView` — Réseau › Amis. The invitations waiting on me come first (inventaire.io
 * notifies nobody, so the app is where they are found), then my friends and the way to add more.
 */
@Composable
private fun FriendsSegment(viewModel: NetworkViewModel, navigator: Navigator) {
    val invitations: List<UserEntity> by viewModel.invitations.collectAsStateWithLifecycle()
    val friends: List<UserEntity> by viewModel.friends.collectAsStateWithLifecycle()
    val community: SyncStatus.State? by viewModel.communityState.collectAsStateWithLifecycle()
    val syncStates: Map<String, FirstSyncState> by viewModel.syncStates.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val sectionState: FriendsSectionState = friendsSectionState(community, friends.size)

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = Spacing.large),
    ) {
        if (invitations.isNotEmpty()) {
            item(key = "invitations-header") {
                SectionHeader(stringResource(R.string.network_profile_invitations))
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
                        HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
                    }
                    LinkRow(stringResource(R.string.network_invitations_all)) { navigator.push(Destination.Invitations) }
                }
            }
        }

        item(key = "friends-header") {
            SectionHeader(stringResource(R.string.network_friends))
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
                        HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
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
