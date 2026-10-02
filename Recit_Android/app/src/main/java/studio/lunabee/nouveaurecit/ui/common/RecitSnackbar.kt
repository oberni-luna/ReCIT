package studio.lunabee.nouveaurecit.ui.common

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarData
import androidx.compose.material3.SnackbarVisuals
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/** The visuals `SnackbarHostState` carries for a [SnackMessage]. */
class RecitSnackbarVisuals(val message2: SnackMessage) : SnackbarVisuals {
    override val message: String = message2.title
    override val actionLabel: String? = null
    override val withDismissAction: Boolean = false
    override val duration: SnackbarDuration = SnackbarDuration.Short
}

/** `SnackBarView`: title over subtitle, on the secondary background, radius 12. */
@Composable
fun RecitSnackbar(data: SnackbarData) {
    val message: SnackMessage? = (data.visuals as? RecitSnackbarVisuals)?.message2
    Snackbar(
        modifier = Modifier.padding(Spacing.medium),
        shape = RoundedCornerShape(CornerRadius.rounded),
        containerColor = RecitTheme.colors.backgroundSecondary,
        contentColor = RecitTheme.colors.foregroundDefault,
    ) {
        Column {
            Text(
                text = message?.title ?: data.visuals.message,
                style = RecitTheme.typography.action300,
                color = if (message?.isError == true) RecitTheme.colors.foregroundError else RecitTheme.colors.foregroundDefault,
            )
            message?.subtitle?.let { Text(text = it, style = RecitTheme.typography.action200) }
        }
    }
}
