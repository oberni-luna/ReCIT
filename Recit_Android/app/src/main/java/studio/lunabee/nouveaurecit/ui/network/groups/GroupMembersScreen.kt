package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupMembership
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.FirstSyncState
import studio.lunabee.nouveaurecit.ui.network.ReaderCell
import studio.lunabee.nouveaurecit.ui.network.SectionCard

/**
 * `GroupMembersView`: everyone in a group, by role — the admins, the members, then, for the admins
 * alone, the requests waiting on them, and the invitations still unanswered. The group is the one
 * its screen just read; this one does not read it again.
 */
@Composable
fun GroupMembersScreen(destination: Destination.GroupMembers, navigator: Navigator) {
    val viewModel: GroupViewModel = recitViewModel(key = destination.id) { GroupViewModel(it, destination.id, fetches = false) }
    val group: ReaderGroup? by viewModel.group.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()
    val people: Map<String, UserEntity> by viewModel.people.collectAsStateWithLifecycle()
    val current: ReaderGroup? = group

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
            memberSection("members", R.string.groups_members_members, users(current.members), GroupRole.Member, ::openUser)

            val requests: List<UserEntity> = users(current.requested)
            if (amAdmin && requests.isNotEmpty()) {
                item(key = "requests-header") { SectionHeader(stringResource(R.string.groups_requests_to_review)) }
                item(key = "requests") {
                    SectionCard {
                        requests.forEachIndexed { index, user ->
                            if (index > 0) RowDivider()
                            ReaderCell(user = user, syncState = FirstSyncState.Synced, onClick = { openUser(user) })
                        }
                    }
                }
            }

            memberSection("invited", R.string.groups_members_invited, users(current.invited), GroupRole.Invited, ::openUser)
        }
    }
}

private fun LazyListScope.memberSection(
    key: String,
    title: Int,
    users: List<UserEntity>,
    role: GroupRole,
    onOpen: (UserEntity) -> Unit,
) {
    if (users.isEmpty()) return
    item(key = "$key-header") { SectionHeader(stringResource(title)) }
    item(key = key) {
        SectionCard {
            users.forEachIndexed { index, user ->
                if (index > 0) RowDivider()
                GroupMemberRow(user = user, role = role, onClick = { onOpen(user) })
            }
        }
    }
}
