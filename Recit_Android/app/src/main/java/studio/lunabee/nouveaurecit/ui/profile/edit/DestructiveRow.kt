package studio.lunabee.nouveaurecit.ui.profile.edit

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.editedition.MinRowHeight

/** A row that takes something away: its words in the error colour, the whole row the target. */
@Composable
internal fun DestructiveRow(text: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = MinRowHeight)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = text, style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundError)
    }
}
