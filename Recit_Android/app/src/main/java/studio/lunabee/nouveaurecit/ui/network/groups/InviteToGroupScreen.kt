package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupAction
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.PillButton
import studio.lunabee.nouveaurecit.designsystem.PillStyle
import studio.lunabee.nouveaurecit.designsystem.RecitSearchField
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.TagStyle
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.FirstSyncState
import studio.lunabee.nouveaurecit.ui.network.ReaderCell
import studio.lunabee.nouveaurecit.ui.network.SectionCard

class InviteToGroupViewModel(private val container: AppContainer, private val groupId: String) : ViewModel() {
    val group: StateFlow<ReaderGroup?> = container.groups.observeGroup(groupId)
        .stateIn(viewModelScope, SharingStarted.Eagerly, container.groups.groups.value[groupId])

    val friends: StateFlow<List<UserEntity>> = container.users.observeByRelation(UserRelation.Friend)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun invite(friend: UserEntity) {
        viewModelScope.launch { container.groups.perform(GroupAction.Invite, groupId, target = friend.id) }
    }
}

/**
 * `InviteToGroupView`: my friends, and where each stands in a group. Any member may invite, not only
 * the admins. Invitations go to friends only: they are the readers the app knows by name, and a
 * stranger is better found by the group's own search.
 */
@Composable
fun InviteToGroupScreen(destination: Destination.InviteToGroup, navigator: Navigator) {
    val viewModel: InviteToGroupViewModel = recitViewModel(key = destination.id) { InviteToGroupViewModel(it, destination.id) }
    val group: ReaderGroup? by viewModel.group.collectAsStateWithLifecycle()
    val allFriends: List<UserEntity> by viewModel.friends.collectAsStateWithLifecycle()
    var query: String by rememberSaveable { mutableStateOf("") }
    val friends: List<UserEntity> = if (query.isBlank()) allFriends else allFriends.filter { it.username.contains(query.trim(), ignoreCase = true) }

    Scaffold(
        topBar = {
            Column {
                RecitTopBar(title = stringResource(R.string.groups_invite), onBack = navigator::pop)
                RecitSearchField(
                    query = query,
                    onQueryChange = { query = it },
                    placeholder = stringResource(R.string.groups_invite_prompt),
                    clearLabel = stringResource(R.string.network_search_clear),
                    autoCorrect = false,
                    modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                )
            }
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(bottom = Spacing.large),
        ) {
            if (friends.isEmpty()) {
                item(key = "empty") {
                    EmptyState(
                        title = stringResource(R.string.groups_invite_no_friends),
                        message = stringResource(R.string.groups_invite_no_friends_message),
                        icon = Icons.Outlined.Groups,
                        modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
                    )
                }
            } else {
                item(key = "friends-header") { SectionHeader(stringResource(R.string.groups_invite_friends)) }
                item(key = "friends") {
                    SectionCard {
                        friends.forEachIndexed { index, friend ->
                            if (index > 0) RowDivider()
                            ReaderCell(
                                user = friend,
                                syncState = FirstSyncState.Synced,
                                onClick = { navigator.push(Destination.User(friend.id)) },
                            ) {
                                InviteTrailingControl(inviteTrailing(group?.role(of = friend.id))) { viewModel.invite(friend) }
                            }
                        }
                    }
                }
                item(key = "footer") {
                    GroupNote(
                        text = stringResource(R.string.groups_invite_footer),
                        modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                    )
                }
            }
        }
    }
}

@Composable
private fun InviteTrailingControl(trailing: InviteTrailing, onInvite: () -> Unit) {
    when (trailing) {
        InviteTrailing.AlreadyMember -> TagLabel(
            text = stringResource(R.string.groups_invite_already_member),
            style = TagStyle.Secondary,
            icon = Icons.Outlined.Check,
        )
        InviteTrailing.Sent -> TagLabel(
            text = stringResource(R.string.groups_invitation_sent),
            style = TagStyle.Secondary,
            icon = Icons.Outlined.Schedule,
        )
        InviteTrailing.Declined -> TagLabel(
            text = stringResource(R.string.groups_invite_declined),
            style = TagStyle.Secondary,
            icon = Icons.Outlined.Close,
        )
        InviteTrailing.Accept -> PillButton(
            text = stringResource(R.string.network_invitation_accept),
            onClick = onInvite,
            style = PillStyle.Prominent,
            icon = Icons.Outlined.Check,
        )
        InviteTrailing.Invite -> PillButton(
            text = stringResource(R.string.groups_invite_action),
            onClick = onInvite,
            icon = Icons.Rounded.Add,
        )
    }
}
