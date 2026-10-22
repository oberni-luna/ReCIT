package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarData
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarVisuals
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.Primitive
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/** The visuals `SnackbarHostState` carries for a [SnackMessage]. */
class RecitSnackbarVisuals(val message2: SnackMessage) : SnackbarVisuals {
    override val message: String = message2.title
    override val actionLabel: String? = message2.actionLabel
    override val withDismissAction: Boolean = false
    override val duration: SnackbarDuration = SnackbarDuration.Short
}

/** `SnackBarView`: title over subtitle, on the inverse background, radius 12, with its action if any. */
@Composable
fun RecitSnackbar(data: SnackbarData) {
    val message: SnackMessage? = (data.visuals as? RecitSnackbarVisuals)?.message2
    Snackbar(
        modifier = Modifier.padding(Spacing.medium),
        shape = RoundedCornerShape(CornerRadius.rounded),
        containerColor = RecitTheme.colors.backgroundInverse,
        contentColor = RecitTheme.colors.foregroundInverse,
        action = data.visuals.actionLabel?.let { label ->
            {
                TextButton(onClick = data::performAction) {
                    Text(label, style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundTintedInverse)
                }
            }
        },
    ) {
        Column {
            Text(
                text = message?.title ?: data.visuals.message,
                style = RecitTheme.typography.action300,
                color = if (message?.isError == true) Primitive.Red400 else RecitTheme.colors.foregroundInverse,
            )
            message?.subtitle?.let { Text(text = it, style = RecitTheme.typography.action200) }
        }
    }
}
