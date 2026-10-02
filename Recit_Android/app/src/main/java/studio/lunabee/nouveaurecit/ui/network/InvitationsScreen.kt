package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun InvitationsScreen(navigator: Navigator) {
    PlaceholderScreen(title = "InvitationsScreen", onBack = navigator::pop)
}
