package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun UserScreen(destination: Destination.User, navigator: Navigator) {
    PlaceholderScreen(title = "UserScreen", onBack = navigator::pop)
}
