package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `ImageSourceMenu`: where a new picture can come from — [removeLabel] first when there is one to
 * take away, then « Remplacer par » over the camera and the gallery of [sources]. Every line closes
 * the menu before it acts.
 */
@Composable
fun ImageSourceMenu(
    expanded: Boolean,
    removeLabel: String,
    showsRemove: Boolean,
    sources: CoverSources,
    onRemove: () -> Unit,
    onDismiss: () -> Unit,
) {
    DropdownMenu(expanded = expanded, onDismissRequest = onDismiss, containerColor = RecitTheme.colors.backgroundRaised) {
        if (showsRemove) {
            MenuLine(removeLabel, Icons.Outlined.Delete, RecitTheme.colors.foregroundError) {
                onDismiss()
                onRemove()
            }
            HorizontalDivider(color = RecitTheme.colors.borderDefault)
            Text(
                text = stringResource(R.string.create_book_cover_replace),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
            )
        }
        MenuLine(stringResource(R.string.create_book_cover_camera), Icons.Outlined.PhotoCamera) {
            onDismiss()
            sources.camera()
        }
        MenuLine(stringResource(R.string.create_book_cover_photos), Icons.Outlined.PhotoLibrary) {
            onDismiss()
            sources.photos()
        }
    }
}

@Composable
private fun MenuLine(text: String, icon: ImageVector, color: Color = RecitTheme.colors.foregroundDefault, onClick: () -> Unit) {
    DropdownMenuItem(
        text = { Text(text, style = RecitTheme.typography.content400, color = color) },
        leadingIcon = { Icon(icon, contentDescription = null, tint = color) },
        onClick = onClick,
    )
}
