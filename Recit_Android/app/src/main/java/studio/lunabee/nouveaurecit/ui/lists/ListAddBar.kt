package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `ListAddBar` (iOS feature 0060): « Ajouter un livre » over « Scanner » and « Rechercher » — « Ajouter
 * un·e auteur·ice » over « Rechercher » alone for a list of authors. Pinned at the foot of the list's
 * screen, in the tab bar's place: a list pushed in Inventaire, Listes or Réseau hides the tab bar (iOS
 * features 0088 and 0089), and the screen's insets keep « Ajouter un livre » above the system navigation
 * bar. Opened from Recherche, which keeps the tab bar, it sits above that bar.
 */
@Composable
internal fun ListAddBar(isAuthor: Boolean, onScan: () -> Unit, onSearch: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundGrouped)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        verticalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Text(
            stringResource(if (isAuthor) R.string.list_detail_add_author else R.string.list_detail_add_work),
            style = RecitTheme.typography.caption200,
            color = RecitTheme.colors.foregroundSecondary,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium)) {
            if (!isAuthor) {
                PrimaryButton(
                    text = stringResource(R.string.list_detail_add_scan),
                    onClick = onScan,
                    icon = Icons.Default.QrCodeScanner,
                    modifier = Modifier.weight(1f),
                )
            }
            PrimaryButton(
                text = stringResource(R.string.list_detail_add_search),
                onClick = onSearch,
                icon = Icons.Default.Search,
                modifier = Modifier.weight(1f),
            )
        }
    }
}
