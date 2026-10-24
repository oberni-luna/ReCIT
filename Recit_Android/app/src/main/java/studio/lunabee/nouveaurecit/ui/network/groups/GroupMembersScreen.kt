package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PersonRemove
import androidx.compose.material.icons.outlined.Verified
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupAction
import studio.lunabee.nouveaurecit.data.groups.GroupMembership
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.SectionCard

/**
 * `GroupMembersView`: everyone in a group, by role — the admins, the members, then, for the admins
 * alone, the requests waiting on them, and the invitations still unanswered. The group is the one
 * its screen just read; this one does not read it again.
 *
 * An admin gets a « … » on each member's line: name them admin, remove them. Never on another
 * admin's line — the server refuses to remove an admin, and has no way to take the role back. Both
 * gestures ask first: neither can be undone from the app.
 */
@Composable
fun GroupMembersScreen(destination: Destination.GroupMembers, navigator: Navigator) {
    val viewModel: GroupViewModel = recitViewModel(key = destination.id) { GroupViewModel(it, destination.id, fetches = false) }
    val group: ReaderGroup? by viewModel.group.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()
    val people: Map<String, UserEntity> by viewModel.people.collectAsStateWithLifecycle()
    val current: ReaderGroup? = group
    var pendingGesture: MemberGesture? by remember { mutableStateOf(null) }

    fun users(memberships: List<GroupMembership>): List<UserEntity> =
        memberships.mapNotNull { people[it.user] }.sortedBy { it.username.lowercase() }

    fun openUser(user: UserEntity) = navigator.push(Destination.User(user.id))

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.groups_members), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(bottom = Spacing.large),
        ) {
            if (current == null) return@LazyColumn
            val amAdmin: Boolean = current.role(of = myUserId) == GroupRole.Admin

            memberSection("admins", R.string.groups_members_admins, users(current.admins), GroupRole.Admin, ::openUser)
            memberSection("members", R.string.groups_members_members, users(current.members), GroupRole.Member, ::openUser) { user ->
                if (amAdmin && user.id != myUserId) {
                    MemberMenu(
                        onMakeAdmin = { pendingGesture = MemberGesture(GroupAction.MakeAdmin, user) },
                        onKick = { pendingGesture = MemberGesture(GroupAction.Kick, user) },
                    )
                }
            }

            val requests: List<UserEntity> = users(current.requested)
            if (amAdmin && requests.isNotEmpty()) {
                item(key = "requests-header") { SectionHeader(stringResource(R.string.groups_requests_to_review)) }
                item(key = "requests") {
                    SectionCard {
                        requests.forEachIndexed { index, user ->
                            if (index > 0) RowDivider()
                            GroupRequestRow(
                                user = user,
                                onOpen = { openUser(user) },
                                onAccept = { viewModel.perform(GroupAction.AcceptRequest, user.id) },
                                onRefuse = { viewModel.perform(GroupAction.RefuseRequest, user.id) },
                            )
                        }
                    }
                }
            }

            memberSection("invited", R.string.groups_members_invited, users(current.invited), GroupRole.Invited, ::openUser)
        }
    }

    pendingGesture?.let { gesture ->
        val isMakingAdmin: Boolean = gesture.action == GroupAction.MakeAdmin
        ConfirmDialog(
            title = stringResource(
                if (isMakingAdmin) R.string.groups_member_make_admin_confirm else R.string.groups_member_kick_confirm,
                gesture.user.username,
            ),
            message = stringResource(if (isMakingAdmin) R.string.groups_member_make_admin_message else R.string.groups_member_kick_message),
            confirmLabel = stringResource(if (isMakingAdmin) R.string.groups_member_make_admin else R.string.groups_member_kick),
            cancelLabel = stringResource(R.string.action_cancel),
            onConfirm = {
                pendingGesture = null
                viewModel.perform(gesture.action, gesture.user.id)
            },
            onDismiss = { pendingGesture = null },
            isDestructive = !isMakingAdmin,
        )
    }
}

/**
 * `MemberGesture`: the two things an admin can do to a member that cannot be taken back from the
 * app — naming an admin has no inverse on the server at all; removing someone means they have to
 * ask or be invited again.
 */
private data class MemberGesture(val action: GroupAction, val user: UserEntity)

@Composable
private fun MemberMenu(onMakeAdmin: () -> Unit, onKick: () -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(
                painterResource(R.drawable.ic_more),
                contentDescription = stringResource(R.string.action_more),
                tint = RecitTheme.colors.foregroundDefault,
            )
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = RecitTheme.colors.backgroundDefault,
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.groups_member_make_admin), color = RecitTheme.colors.foregroundDefault) },
                leadingIcon = { Icon(Icons.Outlined.Verified, contentDescription = null, tint = RecitTheme.colors.foregroundDefault) },
                onClick = {
                    expanded = false
                    onMakeAdmin()
                },
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.groups_member_kick), color = RecitTheme.colors.foregroundDefault) },
                leadingIcon = { Icon(Icons.Outlined.PersonRemove, contentDescription = null, tint = RecitTheme.colors.foregroundDefault) },
                onClick = {
                    expanded = false
                    onKick()
                },
            )
        }
    }
}

private fun LazyListScope.memberSection(
    key: String,
    title: Int,
    users: List<UserEntity>,
    role: GroupRole,
    onOpen: (UserEntity) -> Unit,
    trailing: @Composable (UserEntity) -> Unit = {},
) {
    if (users.isEmpty()) return
    item(key = "$key-header") { SectionHeader(stringResource(title)) }
    item(key = key) {
        SectionCard {
            users.forEachIndexed { index, user ->
                if (index > 0) RowDivider()
                GroupMemberRow(user = user, role = role, onClick = { onOpen(user) }) { trailing(user) }
            }
        }
    }
}
