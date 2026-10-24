package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.MeetingRoom
import androidx.compose.material.icons.outlined.PersonAdd
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MenuDefaults
import androidx.compose.material3.MenuItemColors
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupAction
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.designsystem.DestructiveButton
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.TagStyle
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.LinkRow
import studio.lunabee.nouveaurecit.ui.network.SectionCard

/** How many members a group's screen shows before « Voir les N membres ». */
private const val MEMBERS_PREVIEW_COUNT: Int = 5

/**
 * `GroupDetailView`: one group, as I stand in it. Read afresh each time it opens, whether it came
 * from my list or from a search; what a gesture changes shows at once, since the repository's
 * groups are what the screen collects.
 */
@Composable
fun GroupScreen(destination: Destination.Group, navigator: Navigator) {
    val viewModel: GroupViewModel = recitViewModel(key = destination.id) { GroupViewModel(it, destination.id, fetches = true) }
    val group: ReaderGroup? by viewModel.group.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()
    val people: Map<String, UserEntity> by viewModel.people.collectAsStateWithLifecycle()
    val loadFailed: Boolean by viewModel.loadFailed.collectAsStateWithLifecycle()
    var isConfirmingLeave: Boolean by rememberSaveable { mutableStateOf(false) }
    var isEditingSettings: Boolean by rememberSaveable { mutableStateOf(false) }
    val current: ReaderGroup? = group
    val myRole: GroupRole? = current?.role(of = myUserId)

    Scaffold(
        topBar = {
            RecitTopBar(
                title = current?.name.orEmpty(),
                onBack = navigator::pop,
                actions = {
                    if (current != null && myRole?.belongs == true) {
                        GroupMenu(
                            isAdmin = myRole == GroupRole.Admin,
                            canLeave = myUserId?.let(current::canLeave) == true,
                            onSettings = { isEditingSettings = true },
                            onInvite = { navigator.push(Destination.InviteToGroup(current.id)) },
                            onLeave = { isConfirmingLeave = true },
                        )
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        when {
            current != null -> GroupContent(
                group = current,
                myUserId = myUserId,
                people = people,
                navigator = navigator,
                onPerform = viewModel::perform,
                modifier = Modifier.padding(padding),
            )
            loadFailed -> Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                EmptyState(
                    title = stringResource(R.string.groups_detail_load_failed),
                    message = stringResource(R.string.groups_detail_load_failed_message),
                    icon = Icons.Outlined.ErrorOutline,
                )
            }
            else -> Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted)
            }
        }
    }

    if (isEditingSettings && current != null) {
        GroupSettingsSheet(
            group = current,
            onUpdate = viewModel::update,
            onDismiss = { isEditingSettings = false },
        )
    }

    if (isConfirmingLeave && current != null) {
        ConfirmDialog(
            title = stringResource(R.string.groups_leave_confirm, current.name),
            message = null,
            confirmLabel = stringResource(R.string.groups_leave),
            cancelLabel = stringResource(R.string.action_cancel),
            onConfirm = {
                isConfirmingLeave = false
                viewModel.perform(GroupAction.Leave)
            },
            onDismiss = { isConfirmingLeave = false },
        )
    }
}

/**
 * The « … » of a group I belong to: its settings for an admin, inviting for anyone, and « Quitter »,
 * greyed for the last admin of a group with members.
 */
@Composable
private fun GroupMenu(
    isAdmin: Boolean,
    canLeave: Boolean,
    onSettings: () -> Unit,
    onInvite: () -> Unit,
    onLeave: () -> Unit,
) {
    var expanded: Boolean by rememberSaveable { mutableStateOf(false) }
    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(painterResource(R.drawable.ic_more), contentDescription = stringResource(R.string.action_more))
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundDefault,
        ) {
            if (isAdmin) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.groups_settings)) },
                    leadingIcon = { Icon(Icons.Outlined.Tune, contentDescription = null) },
                    colors = menuItemColors(),
                    onClick = {
                        expanded = false
                        onSettings()
                    },
                )
            }
            DropdownMenuItem(
                text = { Text(stringResource(R.string.groups_invite)) },
                leadingIcon = { Icon(Icons.Outlined.PersonAdd, contentDescription = null) },
                colors = menuItemColors(),
                onClick = {
                    expanded = false
                    onInvite()
                },
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.groups_leave)) },
                leadingIcon = { Icon(Icons.AutoMirrored.Outlined.Logout, contentDescription = null) },
                enabled = canLeave,
                colors = menuItemColors(),
                onClick = {
                    expanded = false
                    onLeave()
                },
            )
        }
    }
}

@Composable
private fun menuItemColors(): MenuItemColors = MenuDefaults.itemColors(
    textColor = RecitTheme.colors.foregroundDefault,
    leadingIconColor = RecitTheme.colors.foregroundDefault,
    disabledTextColor = RecitTheme.colors.foregroundDisable,
    disabledLeadingIconColor = RecitTheme.colors.foregroundDisable,
)

@Composable
private fun GroupContent(
    group: ReaderGroup,
    myUserId: String?,
    people: Map<String, UserEntity>,
    navigator: Navigator,
    onPerform: (GroupAction, String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val myRole: GroupRole? = group.role(of = myUserId)
    val canLeave: Boolean = myUserId?.let(group::canLeave) ?: true
    val members: List<Pair<UserEntity, GroupRole>> = group.memberIds.mapNotNull { id ->
        val user: UserEntity = people[id] ?: return@mapNotNull null
        val role: GroupRole = group.role(of = id) ?: return@mapNotNull null
        user to role
    }
    val requests: List<UserEntity> = group.requested.mapNotNull { people[it.user] }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = Spacing.large),
    ) {
        item(key = "header") { GroupHeader(group) }

        if (groupActionsHaveContent(myRole, canLeave)) {
            item(key = "actions") {
                GroupActions(
                    group = group,
                    myRole = myRole,
                    canLeave = canLeave,
                    invitorName = myUserId?.let(group::invitor)?.let { people[it]?.username },
                    onPerform = { onPerform(it, null) },
                )
            }
        }

        // First for an admin, since these wait on them and nothing else will say so.
        if (myRole == GroupRole.Admin && requests.isNotEmpty()) {
            item(key = "requests-header") { SectionHeader(stringResource(R.string.groups_requests_to_review)) }
            item(key = "requests") {
                SectionCard {
                    requests.forEachIndexed { index, user ->
                        if (index > 0) RowDivider()
                        GroupRequestRow(
                            user = user,
                            onOpen = { navigator.push(Destination.User(user.id)) },
                            onAccept = { onPerform(GroupAction.AcceptRequest, user.id) },
                            onRefuse = { onPerform(GroupAction.RefuseRequest, user.id) },
                        )
                    }
                }
            }
        }

        item(key = "members-header") { SectionHeader(stringResource(R.string.groups_members)) }
        item(key = "members") {
            SectionCard {
                members.take(MEMBERS_PREVIEW_COUNT).forEach { (user, role) ->
                    GroupMemberRow(user = user, role = role, onClick = { navigator.push(Destination.User(user.id)) })
                    RowDivider()
                }
                LinkRow(pluralStringResource(R.plurals.groups_members_see_all, group.memberCount, group.memberCount)) {
                    navigator.push(Destination.GroupMembers(group.id))
                }
                // Any member may invite, not only the admins.
                if (myRole?.belongs == true) {
                    RowDivider()
                    LinkRow(stringResource(R.string.groups_invite)) { navigator.push(Destination.InviteToGroup(group.id)) }
                }
            }
        }
    }
}

/**
 * `GroupActionsView`: what I can do about a group from where I stand in it — ask, take the asking
 * back, answer an invitation — with the sentence that says what the gesture means.
 */
@Composable
private fun GroupActions(
    group: ReaderGroup,
    myRole: GroupRole?,
    canLeave: Boolean,
    invitorName: String?,
    onPerform: (GroupAction) -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium),
    ) {
        when (myRole) {
            null, GroupRole.Declined -> {
                // An open group lets me in at once; any other waits on an admin — the button says which.
                PrimaryButton(
                    text = stringResource(if (group.open) R.string.groups_join else R.string.groups_request),
                    onClick = { onPerform(GroupAction.Request) },
                )
                GroupNote(stringResource(if (group.open) R.string.groups_join_note else R.string.groups_request_note))
            }
            GroupRole.Requested -> {
                SecondaryButton(
                    text = stringResource(R.string.groups_request_awaiting),
                    onClick = {},
                    enabled = false,
                    modifier = Modifier.fillMaxWidth(),
                )
                DestructiveButton(text = stringResource(R.string.groups_request_cancel), onClick = { onPerform(GroupAction.CancelRequest) })
            }
            GroupRole.Invited -> {
                if (invitorName != null) GroupNote(stringResource(R.string.groups_invited_by, invitorName))
                PrimaryButton(text = stringResource(R.string.network_invitation_accept), onClick = { onPerform(GroupAction.Accept) })
                SecondaryButton(
                    text = stringResource(R.string.network_invitation_refuse),
                    onClick = { onPerform(GroupAction.Decline) },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            GroupRole.Admin, GroupRole.Member -> if (!canLeave) GroupNote(stringResource(R.string.groups_leave_last_admin))
        }
    }
}

/**
 * `GroupHeaderView`: the group's picture, its name, what it says of itself — four lines, the rest on
 * a tap — and two facts in tags: who may come in, and how many are there.
 */
@Composable
private fun GroupHeader(group: ReaderGroup) {
    var isDescriptionExpanded: Boolean by rememberSaveable { mutableStateOf(false) }
    Column(
        modifier = Modifier.fillMaxWidth().padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        GroupThumbnail(url = group.pictureUrl, size = ThumbnailSize.Large)
        Text(group.name, style = RecitTheme.typography.title50, color = RecitTheme.colors.foregroundDefault)
        if (group.description.isNotEmpty()) {
            // Up to 5000 characters on the server.
            Text(
                text = group.description,
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundDefault,
                maxLines = if (isDescriptionExpanded) Int.MAX_VALUE else 4,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .animateContentSize()
                    .clickable { isDescriptionExpanded = !isDescriptionExpanded },
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
            TagLabel(
                text = stringResource(if (group.open) R.string.groups_access_open else R.string.groups_access_on_request),
                style = TagStyle.Secondary,
                icon = if (group.open) Icons.Outlined.MeetingRoom else Icons.Outlined.Lock,
            )
            TagLabel(
                text = pluralStringResource(R.plurals.groups_members_count, group.memberCount, group.memberCount),
                style = TagStyle.Secondary,
                icon = Icons.Outlined.Groups,
            )
        }
    }
}
