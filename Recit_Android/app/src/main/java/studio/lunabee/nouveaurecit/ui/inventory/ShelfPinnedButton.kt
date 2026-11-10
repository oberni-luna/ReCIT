package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `formActionBar` (iOS feature 0089): one primary button pinned at the foot, on the surface below it, as
 * `ListAddBar` is — « Ajouter des livres » under an étagère's books, « Ajouter N livres » under the sheet's.
 */
@Composable
internal fun ShelfPinnedButton(
    text: String,
    onClick: () -> Unit,
    background: Color,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(background)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
    ) {
        PrimaryButton(text = text, onClick = onClick, enabled = enabled, modifier = Modifier.fillMaxWidth())
    }
}
