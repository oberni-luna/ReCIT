package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupAction
import studio.lunabee.nouveaurecit.data.groups.MyGroups
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.PillButton
import studio.lunabee.nouveaurecit.designsystem.PillStyle
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.SyncingInlineRow
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.LinkRow
import studio.lunabee.nouveaurecit.ui.network.SectionCard

class GroupsSegmentViewModel(private val container: AppContainer) : ViewModel() {
    val myUserId: StateFlow<String?> = container.users.myUserId

    val myGroups: StateFlow<MyGroups> = container.groups.myGroups
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), MyGroups.Empty)

    val state: StateFlow<GroupsSegmentState> = combine(
        myGroups,
        container.groups.hasLoaded,
        container.syncStatus.domains.map { it[SyncStatus.Domain.Groups] },
        ::groupsSegmentState,
    ).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), GroupsSegmentState.Syncing)

    /** Whoever sent me an invitation, by id — the line under each invitation. */
    val invitors: StateFlow<Map<String, UserEntity>> = combine(myGroups, myUserId) { groups, me ->
        me?.let { id -> groups.invitations.mapNotNull { it.invitor(of = id) }.toSet() }.orEmpty()
    }
        .distinctUntilChanged()
        .flatMapLatest(container.users::observeUsers)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    /** Answers an invitation from its row: the group moves to « Mes groupes », or leaves the segment. */
    fun answer(groupId: String, accept: Boolean) {
        viewModelScope.launch { container.groups.perform(if (accept) GroupAction.Accept else GroupAction.Decline, groupId) }
    }
}

/**
 * `GroupsSegmentView` — Réseau › Groupes: the invitations waiting on me first, since nothing else
 * will tell me about them, then my groups, then the requests I sent that nobody has answered.
 */
@Composable
fun GroupsSegment(navigator: Navigator) {
    val viewModel: GroupsSegmentViewModel = recitViewModel { GroupsSegmentViewModel(it) }
    val state: GroupsSegmentState by viewModel.state.collectAsStateWithLifecycle()
    val groups: MyGroups by viewModel.myGroups.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()
    val invitors: Map<String, UserEntity> by viewModel.invitors.collectAsStateWithLifecycle()

    fun open(group: ReaderGroup) = navigator.push(Destination.Group(group.id))

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = Spacing.large),
    ) {
        when (state) {
            GroupsSegmentState.Syncing -> item(key = "syncing") {
                SyncingInlineRow(
                    message = stringResource(R.string.sync_loading),
                    modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                )
            }
            GroupsSegmentState.Failed -> item(key = "failed") {
                Text(
                    text = stringResource(R.string.groups_load_failed),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundSecondary,
                    modifier = Modifier.fillMaxWidth().padding(Spacing.medium),
                )
            }
            GroupsSegmentState.Empty -> item(key = "empty") {
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    EmptyState(
                        title = stringResource(R.string.groups_empty_title),
                        message = stringResource(R.string.groups_empty_message),
                        icon = Icons.Outlined.Groups,
                        actionTitle = stringResource(R.string.groups_find),
                        onAction = { navigator.push(Destination.FindGroups) },
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }
            GroupsSegmentState.Groups -> {
                if (groups.invitations.isNotEmpty()) {
                    item(key = "invitations-header") { SectionHeader(stringResource(R.string.groups_invitations)) }
                    item(key = "invitations") {
                        SectionCard {
                            groups.invitations.forEachIndexed { index, group ->
                                if (index > 0) RowDivider()
                                GroupInvitationRow(
                                    group = group,
                                    invitorName = myUserId?.let { group.invitor(of = it) }?.let { invitors[it]?.username },
                                    onOpen = { open(group) },
                                    onAccept = { viewModel.answer(group.id, accept = true) },
                                    onRefuse = { viewModel.answer(group.id, accept = false) },
                                )
                            }
                        }
                    }
                }
                if (groups.mine.isNotEmpty()) {
                    item(key = "mine-header") { SectionHeader(stringResource(R.string.groups_mine)) }
                    item(key = "mine") {
                        SectionCard {
                            groups.mine.forEachIndexed { index, group ->
                                if (index > 0) RowDivider()
                                GroupRow(
                                    group = group,
                                    role = group.role(of = myUserId),
                                    onClick = { open(group) },
                                    pendingCount = group.requestsToReview(by = myUserId),
                                )
                            }
                        }
                    }
                }
                if (groups.sentRequests.isNotEmpty()) {
                    item(key = "requests-header") { SectionHeader(stringResource(R.string.groups_requests_sent)) }
                    item(key = "requests") {
                        SectionCard {
                            groups.sentRequests.forEachIndexed { index, group ->
                                if (index > 0) RowDivider()
                                GroupRow(group = group, role = group.role(of = myUserId), onClick = { open(group) })
                            }
                        }
                    }
                }
                item(key = "links") {
                    SectionCard(Modifier.padding(top = Spacing.medium)) {
                        LinkRow(stringResource(R.string.groups_find)) { navigator.push(Destination.FindGroups) }
                    }
                }
            }
        }
    }
}

/**
 * `GroupInvitationRowView`: which group, who asked, and the two answers — laid out like a reader's
 * invitation, the answers under the group rather than beside it: a « yes » wider than a thumb, and
 * a « no » that is tinted and never red, since declining destroys nothing.
 */
@Composable
private fun GroupInvitationRow(
    group: ReaderGroup,
    invitorName: String?,
    onOpen: () -> Unit,
    onAccept: () -> Unit,
    onRefuse: () -> Unit,
) {
    Column(Modifier.fillMaxWidth().padding(bottom = Spacing.small)) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onOpen)
                .padding(horizontal = Spacing.medium, vertical = Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        ) {
            GroupCell(
                name = group.name,
                pictureUrl = group.pictureUrl,
                detail = pluralStringResource(R.plurals.groups_members_count, group.memberCount, group.memberCount),
            )
            if (invitorName != null) {
                Text(
                    text = stringResource(R.string.groups_invited_by, invitorName),
                    style = RecitTheme.typography.footnote200,
                    color = RecitTheme.colors.foregroundSecondary,
                )
            }
        }
        Row(
            modifier = Modifier.padding(horizontal = Spacing.medium),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
        ) {
            PillButton(text = stringResource(R.string.network_invitation_accept), onClick = onAccept, style = PillStyle.Prominent)
            PillButton(text = stringResource(R.string.network_invitation_refuse), onClick = onRefuse)
        }
    }
}

@Composable
internal fun RowDivider() {
    HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
}
