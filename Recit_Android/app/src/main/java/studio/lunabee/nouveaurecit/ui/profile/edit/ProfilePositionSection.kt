package studio.lunabee.nouveaurecit.ui.profile.edit

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Place
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.Coordinates
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.MinRowHeight

/**
 * `ProfilePositionSection` (iOS feature 0055): « Position » in « Modifier le profil » — where the account is,
 * as a map that does not move, the row that opens the position's page, and « Retirer ma position ».
 * Without a position, a sentence says what that costs instead of an empty map.
 */
@Composable
fun ProfilePositionSection(
    position: Coordinates?,
    onEdit: () -> Unit,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FormSection(
        header = stringResource(R.string.edit_profile_position_header),
        footer = stringResource(if (position == null) R.string.edit_profile_position_none else R.string.edit_profile_position_footer),
        modifier = modifier,
    ) {
        if (position != null) {
            // A new position, a new map: the still one is only ever placed once.
            key(position) {
                PositionMap(
                    target = position,
                    zoom = PREVIEW_ZOOM,
                    interactive = false,
                    modifier = Modifier
                        .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium)
                        .fillMaxWidth()
                        .height(PreviewHeight)
                        .clip(RoundedCornerShape(CornerRadius.medium)),
                )
            }
            FormDivider()
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = MinRowHeight)
                .clickable(role = Role.Button, onClick = onEdit)
                .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Place, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
            Text(
                text = stringResource(if (position == null) R.string.edit_profile_position_add else R.string.edit_profile_position_edit),
                style = RecitTheme.typography.action300,
                color = RecitTheme.colors.foregroundTinted,
            )
        }
        if (position != null) {
            FormDivider()
            DestructiveRow(text = stringResource(R.string.profile_position_remove), onClick = onRemove)
        }
    }
}

/** iOS's 0.06° span around the position. */
private const val PREVIEW_ZOOM: Double = 13.0

private val PreviewHeight: Dp = 164.dp
