package studio.lunabee.nouveaurecit.ui.root

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.auth.AuthFlow
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer

/**
 * `RootView`: signed out → the account flow, pinned to dark as iOS pins it; signed in → the tabs,
 * with the sync started. Every way a session ends forgets the user and keeps the books (feature 0025).
 */
@Composable
fun RootScreen() {
    val container: AppContainer = LocalAppContainer.current
    val isAuthenticated: Boolean by container.auth.isAuthenticated.collectAsState()

    LaunchedEffect(isAuthenticated) {
        if (isAuthenticated) container.session.refreshUserData() else container.session.forgetSignedOutUser()
    }

    if (isAuthenticated) {
        RecitTheme { MainScaffold() }
    } else {
        RecitTheme(darkTheme = true) { AuthFlow() }
    }
}
