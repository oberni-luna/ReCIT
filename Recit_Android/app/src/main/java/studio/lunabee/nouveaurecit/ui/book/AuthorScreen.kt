package studio.lunabee.nouveaurecit.ui.book

import androidx.compose.runtime.Composable
import studio.lunabee.nouveaurecit.ui.common.PlaceholderScreen
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

@Composable
fun AuthorScreen(destination: Destination.Author, navigator: Navigator) {
    PlaceholderScreen(title = "AuthorScreen", onBack = navigator::pop)
}
