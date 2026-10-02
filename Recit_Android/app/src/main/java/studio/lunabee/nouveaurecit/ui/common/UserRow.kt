package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.CellThumbnail
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.ThumbnailShape
import studio.lunabee.nouveaurecit.designsystem.ThumbnailSize

/**
 * `UserCellView`: a round avatar, the username, and a line under it ([subtitle], e.g.
 * « Membre depuis … »). [trailing] holds a row's action (a pill, a tag).
 */
@Composable
fun UserRow(
    user: UserEntity,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    onClick: (() -> Unit)? = null,
    avatarSize: ThumbnailSize = ThumbnailSize.Medium,
    trailing: @Composable RowScope.() -> Unit = {},
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CellThumbnail(url = user.avatarUrl, size = avatarSize, shape = ThumbnailShape.Circle)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(user.username, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            subtitle?.let { Text(it, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary) }
        }
        trailing()
    }
}
