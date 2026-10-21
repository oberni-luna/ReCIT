package studio.lunabee.nouveaurecit.ui.profile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.RecitSnackbar
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.appEntries

/**
 * `ProfileSheet` (feature 0038): the profile at full height over the tabs, with a back stack of its
 * own so that what it pushes — À propos, deleting the account — stays inside it. The system back
 * pops inside it first, then closes it. It starts from its root each time it opens.
 *
 * Signing out or deleting the account from here needs nothing more: the root swaps the whole shell,
 * this sheet with it, for the welcome screen.
 *
 * It carries its own snackbar host, since the shell's is under it.
 */
@Composable
fun ProfileSheet(onClose: () -> Unit, snackbarHostState: SnackbarHostState) {
    val backStack: NavBackStack<NavKey> = rememberNavBackStack(Destination.ProfileRoot)
    val navigator: Navigator = remember(backStack) { Navigator(backStack) }
    // Composed before the stack's own handler, which therefore wins while there is something to pop.
    BackHandler(onBack = onClose)
    Surface(modifier = Modifier.fillMaxSize(), color = RecitTheme.colors.backgroundSecondary) {
        Box(Modifier.fillMaxSize()) {
            NavDisplay(
                backStack = backStack,
                onBack = { navigator.pop() },
                entryDecorators = listOf(
                    rememberSaveableStateHolderNavEntryDecorator(),
                    rememberViewModelStoreNavEntryDecorator(),
                ),
                entryProvider = entryProvider { appEntries(navigator) },
            )
            SnackbarHost(snackbarHostState, Modifier.align(Alignment.BottomCenter).navigationBarsPadding()) { RecitSnackbar(it) }
        }
    }
}
