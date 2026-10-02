package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.PillButton
import studio.lunabee.nouveaurecit.designsystem.PillStyle
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.TagLabel
import studio.lunabee.nouveaurecit.designsystem.TagStyle
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize
import studio.lunabee.nouveaurecit.ui.common.Formatting
import studio.lunabee.nouveaurecit.ui.common.UserRow

/**
 * `UserCellView`: a reader in a list. Under the name, « Membre depuis … » — or, for a friend whose
 * books have never landed, how far their first sync has got (feature 0027). Strangers never get
 * the bar: nobody syncs their inventory, so they would wait for ever.
 */
@Composable
fun ReaderCell(
    user: UserEntity,
    syncState: FirstSyncState,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    trailing: @Composable RowScope.() -> Unit = {},
) {
    val showsProgress: Boolean = user.relation == UserRelation.Friend && syncState != FirstSyncState.Synced
    if (!showsProgress) {
        UserRow(
            user = user,
            modifier = modifier,
            subtitle = user.created?.let { stringResource(R.string.user_member_since, Formatting.monthYear(it)) },
            onClick = onClick,
            trailing = trailing,
        )
        return
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.Top,
    ) {
        CellThumbnail(url = user.avatarUrl, size = ThumbnailSize.Medium, shape = ThumbnailShape.Circle)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(user.username, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            SyncProgressBar(syncState)
            SyncCaption(syncState)
        }
        trailing()
    }
}

/** `InventorySyncProgressBar`: determinate once the total is announced, indeterminate before. */
@Composable
fun SyncProgressBar(state: FirstSyncState, modifier: Modifier = Modifier) {
    val fraction: Float? = (state as? FirstSyncState.Running)?.progress?.fraction
    if (fraction != null) {
        LinearProgressIndicator(
            progress = { fraction },
            modifier = modifier.fillMaxWidth(),
            color = RecitTheme.colors.foregroundTinted,
            trackColor = RecitTheme.colors.backgroundDisable,
        )
    } else {
        LinearProgressIndicator(
            modifier = modifier.fillMaxWidth(),
            color = RecitTheme.colors.foregroundTinted,
            trackColor = RecitTheme.colors.backgroundDisable,
        )
    }
}

/** `InventorySyncCaption`. */
@Composable
fun SyncCaption(state: FirstSyncState) {
    val text: String = when (state) {
        FirstSyncState.Synced -> return
        FirstSyncState.Waiting -> stringResource(R.string.network_sync_inventory_waiting)
        is FirstSyncState.Running -> state.progress.announced?.let {
            stringResource(R.string.network_sync_inventory_count, state.progress.received, it)
        } ?: stringResource(R.string.network_sync_inventory_preparing)
    }
    Text(text, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
}

/** `InventorySyncBanner`: the title, a percentage (or a spinner), the bar, and what has arrived. */
@Composable
fun InventorySyncBanner(title: String, state: FirstSyncState, modifier: Modifier = Modifier) {
    val progress = (state as? FirstSyncState.Running)?.progress
    val fraction: Float? = progress?.fraction
    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.small),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.small)) {
            Text(
                title,
                style = RecitTheme.typography.action300,
                color = RecitTheme.colors.foregroundDefault,
                modifier = Modifier.weight(1f),
            )
            if (fraction != null) {
                Text("${(fraction * 100).toInt()} %", style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary)
            } else {
                CircularProgressIndicator(Modifier.size(12.dp), strokeWidth = 1.5.dp, color = RecitTheme.colors.foregroundSecondary)
            }
        }
        SyncProgressBar(state)
        val announced: Int? = progress?.announced
        val caption: String = when {
            progress != null && announced != null ->
                stringResource(R.string.network_sync_inventory_count_arriving, progress.received, announced)
            progress != null -> stringResource(R.string.network_sync_inventory_preparing)
            else -> stringResource(R.string.network_sync_inventory_waiting)
        }
        Text(caption, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary)
    }
}

/**
 * `InvitationRowView`: who is asking, and the two answers under them — Accepter prominent,
 * Refuser tinted, neither destructive.
 */
@Composable
fun InvitationRow(
    user: UserEntity,
    syncState: FirstSyncState,
    onOpen: () -> Unit,
    onAccept: () -> Unit,
    onRefuse: () -> Unit,
) {
    Column(Modifier.fillMaxWidth().padding(bottom = Spacing.small)) {
        ReaderCell(user = user, syncState = syncState, onClick = onOpen)
        Row(
            modifier = Modifier.padding(horizontal = Spacing.medium),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
        ) {
            PillButton(text = stringResource(R.string.network_invitation_accept), onClick = onAccept, style = PillStyle.Prominent)
            PillButton(text = stringResource(R.string.network_invitation_refuse), onClick = onRefuse)
        }
    }
}

/**
 * `ReaderRowView`: two targets — the name opens the profile, the end of the line acts. A friend
 * gets nothing at the end: the relation is settled.
 */
@Composable
fun ReaderRow(
    user: UserEntity,
    syncState: FirstSyncState,
    onOpen: () -> Unit,
    onAdd: () -> Unit,
) {
    ReaderCell(user = user, syncState = syncState, onClick = onOpen) {
        when (readerTrailing(user.relation)) {
            ReaderTrailing.Add -> PillButton(
                text = stringResource(R.string.action_add),
                onClick = onAdd,
                icon = Icons.Rounded.Add,
            )
            ReaderTrailing.Sent -> TagLabel(
                text = stringResource(R.string.network_request_sent),
                style = TagStyle.Secondary,
                icon = Icons.Outlined.Schedule,
            )
            ReaderTrailing.Received -> TagLabel(
                text = stringResource(R.string.network_invitation_received),
                icon = Icons.Outlined.Email,
            )
            ReaderTrailing.Nothing -> Unit
        }
    }
}

/** A tinted `NavigationLink` row in action300 (« Toutes les invitations », « Ajouter des amis lecteurs »). */
@Composable
fun LinkRow(text: String, onClick: () -> Unit) {
    Text(
        text = text,
        style = RecitTheme.typography.action300,
        color = RecitTheme.colors.foregroundTinted,
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
    )
}

/** An inset-grouped `Section`'s card: the rows of one section, on the default background. */
@Composable
fun SectionCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .clip(RoundedCornerShape(CornerRadius.rounded))
            .background(RecitTheme.colors.backgroundDefault),
        content = content,
    )
}

/** A plain line of text in a list section (« Aucun ami pour le moment », « Oh, c'est vide ici »). */
@Composable
fun PlainRow(text: String) {
    Text(
        text = text,
        style = RecitTheme.typography.content300,
        color = RecitTheme.colors.foregroundDefault,
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
    )
}
