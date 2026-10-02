package studio.lunabee.nouveaurecit.ui.auth

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import kotlinx.serialization.Serializable

/** `AuthDestination`: the signed-out stack. Reached by replacing, so it never grows past one level. */
@Serializable
sealed interface AuthDestination : NavKey {
    @Serializable data object Welcome : AuthDestination
    @Serializable data object SignIn : AuthDestination
    @Serializable data object CreateAccount : AuthDestination
}

/** `AuthFlowView`: the welcome screen and the two account screens it opens. */
@Composable
fun AuthFlow() {
    val backStack: NavBackStack<NavKey> = rememberNavBackStack(AuthDestination.Welcome)
    val open: (AuthDestination) -> Unit = { destination ->
        while (backStack.size > 1) backStack.removeAt(backStack.lastIndex)
        backStack.add(destination)
    }
    val back: () -> Unit = { if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) }

    NavDisplay(
        backStack = backStack,
        onBack = back,
        entryDecorators = listOf(
            rememberSaveableStateHolderNavEntryDecorator(),
            rememberViewModelStoreNavEntryDecorator(),
        ),
        entryProvider = entryProvider {
            entry<AuthDestination.Welcome> {
                WelcomeScreen(
                    onSignIn = { open(AuthDestination.SignIn) },
                    onCreateAccount = { open(AuthDestination.CreateAccount) },
                )
            }
            entry<AuthDestination.SignIn> { SignInScreen(onBack = back) }
            entry<AuthDestination.CreateAccount> { CreateAccountScreen(onBack = back) }
        },
    )
}
