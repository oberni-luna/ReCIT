package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun EntityListScreen(destination: Destination.EntityList, navigator: Navigator) {
    PlaceholderScreen(title = "EntityListScreen", onBack = navigator::pop)
}
