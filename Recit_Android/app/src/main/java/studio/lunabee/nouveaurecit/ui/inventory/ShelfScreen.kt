package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun ShelfScreen(destination: Destination.Shelf, navigator: Navigator) {
    PlaceholderScreen(title = "ShelfScreen", onBack = navigator::pop)
}
