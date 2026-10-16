package studio.lunabee.nouveaurecit.ui.flow

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.EntryProviderScope
import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import kotlinx.serialization.Serializable
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.RecitSnackbar
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.appEntries
import studio.lunabee.nouveaurecit.ui.scan.ScanCameraScreen

/**
 * `SortFlowRoute` (ADR 0007): the screens that exist only inside the flow. They are not cases of the
 * app-wide [Destination] — nothing outside the flow can reach in.
 */
@Serializable
sealed interface FlowDestination : NavKey {
    @Serializable data object Camera : FlowDestination
}

/**
 * `SortFlowView` (ADR 0007): one full-screen flow, owning its own back stack, entered at a route.
 * Drawn by `MainScaffold` above its tabs and navigation bar, so nothing of the shell shows through;
 * the snackbar is drawn above it, which is what lets a failed add be read from inside the camera.
 *
 * The flow's stack also takes the app's destinations, so a scanned book opens without tearing the
 * session down. It is not saved: the flow reopens at its start route after the activity is recreated.
 */
@Composable
fun SortFlowHost(start: SortFlowStart, onClose: () -> Unit, snackbarHostState: SnackbarHostState) {
    val backStack: NavBackStack<NavKey> = remember(start) { NavBackStack(rootOf(start)) }
    val navigator: Navigator = remember(backStack) { Navigator(backStack) }

    Box(
        Modifier
            .fillMaxSize()
            .background(RecitTheme.colors.backgroundDefault)
            // A touch the flow's screens leave unhandled must not reach the tabs underneath.
            .pointerInput(Unit) { awaitEachGesture { awaitFirstDown(requireUnconsumed = false) } },
    ) {
        NavDisplay(
            backStack = backStack,
            onBack = { if (backStack.size > 1) navigator.pop() else onClose() },
            entryDecorators = listOf(
                rememberSaveableStateHolderNavEntryDecorator(),
                rememberViewModelStoreNavEntryDecorator(),
            ),
            entryProvider = entryProvider {
                flowEntries(navigator = navigator, onClose = onClose)
                appEntries(navigator)
            },
        )
        SnackbarHost(snackbarHostState, Modifier.align(Alignment.BottomCenter).navigationBarsPadding()) { RecitSnackbar(it) }
    }
}

private fun rootOf(start: SortFlowStart): NavKey = when (start) {
    SortFlowStart.Scanning -> FlowDestination.Camera
}

private fun EntryProviderScope<NavKey>.flowEntries(navigator: Navigator, onClose: () -> Unit) {
    entry<FlowDestination.Camera> {
        ScanCameraScreen(
            onOpenBook = { book -> navigator.push(Destination.Book(BookAnchor.Edition(book.uri))) },
            onFinished = { _, _ -> onClose() },
        )
    }
}
