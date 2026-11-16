package studio.lunabee.nouveaurecit.ui.root

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavEntry
import androidx.navigation3.runtime.NavEntryDecorator
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.LocalStackClose
import studio.lunabee.nouveaurecit.ui.common.RecitSnackbar
import studio.lunabee.nouveaurecit.ui.navigation.CoversTabs
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.LinkTarget
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.appEntries

/**
 * `LinkSheet` (issue 143): the screen an Ex-libris link names, opened over an overlay rather than under it — the
 * Profil, « Ranger mes livres », a bottom sheet. A full-screen dialog, so that it comes above a bottom sheet's own
 * window, with a back stack of its own: what it pushes stays in it, and « Fermer » on its root, or the system back
 * there, hands back the overlay as it was. My own name opens the Profil's root in it.
 *
 * It carries its own snackbar host, since the shell's is under it.
 */
@Composable
fun LinkDialog(target: LinkTarget, onClose: () -> Unit, snackbarHostState: SnackbarHostState) {
    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        CoversTabs()
        val root: Destination = when (target) {
            is LinkTarget.Screen -> target.destination
            LinkTarget.Profile -> Destination.ProfileRoot
        }
        val backStack: NavBackStack<NavKey> = rememberNavBackStack(root)
        val navigator: Navigator = remember(backStack) { Navigator(backStack) }
        val entries: (NavKey) -> NavEntry<NavKey> = remember(navigator) { entryProvider { appEntries(navigator) } }
        val rootContentKey: Any = remember(entries, root) { entries(root).contentKey }
        Surface(modifier = Modifier.fillMaxSize(), color = RecitTheme.colors.backgroundDefault) {
            Box(Modifier.fillMaxSize()) {
                NavDisplay(
                    backStack = backStack,
                    onBack = { navigator.pop() },
                    entryDecorators = listOf(
                        rememberSaveableStateHolderNavEntryDecorator(),
                        rememberViewModelStoreNavEntryDecorator(),
                        closeOnRootDecorator(rootContentKey, onClose),
                    ),
                    entryProvider = entries,
                )
                SnackbarHost(snackbarHostState, Modifier.align(Alignment.BottomCenter).navigationBarsPadding()) { RecitSnackbar(it) }
            }
        }
    }
}

/** « Fermer » in the root screen's top bar, the chevron in every screen pushed above it. */
private fun closeOnRootDecorator(rootContentKey: Any, onClose: () -> Unit): NavEntryDecorator<NavKey> =
    NavEntryDecorator { entry ->
        if (entry.contentKey == rootContentKey) {
            CompositionLocalProvider(LocalStackClose provides onClose) { entry.Content() }
        } else {
            entry.Content()
        }
    }
