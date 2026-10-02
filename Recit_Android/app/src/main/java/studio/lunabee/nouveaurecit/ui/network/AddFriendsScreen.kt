package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun AddFriendsScreen(navigator: Navigator) {
    PlaceholderScreen(title = "AddFriendsScreen", onBack = navigator::pop)
}
