package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.GroupRole
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.TagStyle
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.network.FirstSyncState
import studio.lunabee.nouveaurecit.ui.network.ReaderCell

/**
 * `AvatarThumbnail(.group)`: a group's picture as a square with rounded corners, where a reader's is
 * a circle — a group should never be read as a person at a glance. Without a picture, or when it
 * will not load, the square shows the groups glyph on the tinted fill.
 */
@Composable
fun GroupThumbnail(url: String?, size: ThumbnailSize, modifier: Modifier = Modifier) {
    val shape: Shape = RoundedCornerShape(CornerRadius.medium)
    Box(
        modifier = modifier
            .size(size.width)
            .shadow(elevation = 1.dp, shape = shape)
            .clip(shape)
            .background(RecitTheme.colors.backgroundTinted),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.Outlined.Groups,
            contentDescription = null,
            tint = RecitTheme.colors.foregroundTinted,
            modifier = Modifier.size(size.width / 2),
        )
        if (url != null) {
            AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        }
    }
}

/**
 * `GroupCellView` and `GroupRowView`: a group in a list — its picture, its name, a second line
 * ([detail]: how many people, or what the group says of itself), and where I stand in it at the end
 * of the line. A dot follows the name when the group waits on me ([pendingCount], feature 0033).
 */
@Composable
fun GroupRow(
    name: String,
    pictureUrl: String?,
    detail: String?,
    role: GroupRole?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    pendingCount: Int = 0,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        GroupCell(name = name, pictureUrl = pictureUrl, detail = detail, pendingCount = pendingCount, modifier = Modifier.weight(1f))
        GroupRoleTag(role)
    }
}

/** A group I hold a role in, its member count under its name. */
@Composable
fun GroupRow(
    group: ReaderGroup,
    role: GroupRole?,
    onClick: () -> Unit,
    pendingCount: Int = 0,
) {
    GroupRow(
        name = group.name,
        pictureUrl = group.pictureUrl,
        detail = pluralStringResource(R.plurals.groups_members_count, group.memberCount, group.memberCount),
        role = role,
        onClick = onClick,
        pendingCount = pendingCount,
    )
}

@Composable
fun GroupCell(
    name: String,
    pictureUrl: String?,
    detail: String?,
    modifier: Modifier = Modifier,
    pendingCount: Int = 0,
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.Top,
    ) {
        GroupThumbnail(url = pictureUrl, size = ThumbnailSize.Medium)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.small), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = name,
                    style = RecitTheme.typography.content400Bold,
                    color = RecitTheme.colors.foregroundDefault,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (pendingCount > 0) PendingDot(pendingCount)
            }
            if (!detail.isNullOrEmpty()) {
                Text(
                    text = detail,
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundDefault,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

/**
 * `PendingDot`: the red dot after a group's name when it waits on me — red like the tab's badge it
 * accounts for, through the design system's red. No figure inside: the group's screen lists the
 * requests, and the dot only has to say where.
 */
@Composable
fun PendingDot(count: Int) {
    val description: String = pluralStringResource(R.plurals.groups_requests_pending, count, count)
    Box(
        Modifier
            .size(10.dp)
            .clip(CircleShape)
            .background(RecitTheme.colors.foregroundError)
            .semantics { contentDescription = description },
    )
}

/**
 * `GroupRoleTag`: where I stand in a group, at the end of its row. A member gets nothing: an empty
 * end of line is what says the membership is settled.
 */
@Composable
fun GroupRoleTag(role: GroupRole?) {
    when (role) {
        GroupRole.Admin -> TagLabel(text = stringResource(R.string.groups_role_admin), icon = Icons.Outlined.Verified)
        GroupRole.Requested -> TagLabel(
            text = stringResource(R.string.groups_request_sent),
            style = TagStyle.Secondary,
            icon = Icons.Outlined.Schedule,
        )
        GroupRole.Invited -> TagLabel(text = stringResource(R.string.groups_invitation_received), icon = Icons.Outlined.Email)
        GroupRole.Member, GroupRole.Declined, null -> Unit
    }
}

/** `GroupMemberRowView`: a person seen from a group — their cell, and their role when it is worth saying. */
@Composable
fun GroupMemberRow(
    user: UserEntity,
    role: GroupRole,
    onClick: () -> Unit,
    trailing: @Composable () -> Unit = {},
) {
    ReaderCell(user = user, syncState = FirstSyncState.Synced, onClick = onClick) {
        when (role) {
            GroupRole.Admin -> TagLabel(text = stringResource(R.string.groups_role_admin), icon = Icons.Outlined.Verified)
            GroupRole.Invited -> TagLabel(
                text = stringResource(R.string.groups_invitation_sent),
                style = TagStyle.Secondary,
                icon = Icons.Outlined.Schedule,
            )
            GroupRole.Member, GroupRole.Requested, GroupRole.Declined -> Unit
        }
        trailing()
    }
}

/** `GroupNote`: the footnote that says what a gesture costs, under a group's buttons. */
@Composable
fun GroupNote(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = RecitTheme.typography.footnote200,
        color = RecitTheme.colors.foregroundSecondary,
        modifier = modifier.fillMaxWidth(),
    )
}
