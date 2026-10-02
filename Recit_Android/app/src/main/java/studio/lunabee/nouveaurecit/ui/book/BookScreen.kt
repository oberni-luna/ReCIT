package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun BookScreen(destination: Destination.Book, navigator: Navigator) {
    PlaceholderScreen(title = "BookScreen", onBack = navigator::pop)
}
