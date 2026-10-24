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
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.MeetingRoom
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.TagStyle
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.FirstSyncState
import studio.lunabee.nouveaurecit.ui.network.LinkRow
import studio.lunabee.nouveaurecit.ui.network.ReaderCell
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
    val current: ReaderGroup? = group

    Scaffold(
        topBar = {
            RecitTopBar(title = current?.name.orEmpty(), onBack = navigator::pop)
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        when {
            current != null -> GroupContent(
                group = current,
                myUserId = myUserId,
                people = people,
                navigator = navigator,
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
}

@Composable
private fun GroupContent(
    group: ReaderGroup,
    myUserId: String?,
    people: Map<String, UserEntity>,
    navigator: Navigator,
    modifier: Modifier = Modifier,
) {
    val myRole: GroupRole? = group.role(of = myUserId)
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

        // First for an admin, since these wait on them and nothing else will say so.
        if (myRole == GroupRole.Admin && requests.isNotEmpty()) {
            item(key = "requests-header") { SectionHeader(stringResource(R.string.groups_requests_to_review)) }
            item(key = "requests") {
                SectionCard {
                    requests.forEachIndexed { index, user ->
                        if (index > 0) RowDivider()
                        ReaderCell(user = user, syncState = FirstSyncState.Synced, onClick = { navigator.push(Destination.User(user.id)) })
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
            }
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
