package studio.lunabee.nouveaurecit.designsystem

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

/**
 * The confirmation every irreversible gesture goes through: a title, what it costs, then
 * « Annuler » and the confirming verb side by side, the verb last and red when it destroys —
 * the Material order, never stacked.
 */
@Composable
fun ConfirmDialog(
    title: String?,
    message: String?,
    confirmLabel: String,
    cancelLabel: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    isDestructive: Boolean = true,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = title?.let { { Text(it, style = RecitTheme.typography.title50) } },
        text = message?.let { { Text(it, style = RecitTheme.typography.content300) } },
        confirmButton = {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Spacing.small, Alignment.End)) {
                TextButton(onClick = onDismiss) {
                    Text(cancelLabel, style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundTinted)
                }
                TextButton(onClick = onConfirm) {
                    Text(
                        confirmLabel,
                        style = RecitTheme.typography.action300,
                        color = if (isDestructive) RecitTheme.colors.foregroundError else RecitTheme.colors.foregroundTinted,
                    )
                }
            }
        },
        containerColor = RecitTheme.colors.backgroundRaised,
        titleContentColor = RecitTheme.colors.foregroundDefault,
        textContentColor = RecitTheme.colors.foregroundDefault,
    )
}
