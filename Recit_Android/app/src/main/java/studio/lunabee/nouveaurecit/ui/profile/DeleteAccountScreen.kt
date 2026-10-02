package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun DeleteAccountScreen(navigator: Navigator) {
    PlaceholderScreen(title = "DeleteAccountScreen", onBack = navigator::pop)
}
