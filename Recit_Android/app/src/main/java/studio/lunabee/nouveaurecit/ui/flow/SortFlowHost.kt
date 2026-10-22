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
import studio.lunabee.nouveaurecit.data.sorting.SortSectionId
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.RecitSnackbar
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.appEntries
import studio.lunabee.nouveaurecit.ui.scan.ScanCameraScreen
import studio.lunabee.nouveaurecit.ui.sort.ScanTallyScreen
import studio.lunabee.nouveaurecit.ui.sort.SortShelfScreen
import studio.lunabee.nouveaurecit.ui.sort.SortSurfaceScreen

/**
 * `SortFlowRoute` (ADR 0007): the screens that exist only inside the flow. They are not cases of the
 * app-wide [Destination] — nothing outside the flow can reach in.
 */
@Serializable
sealed interface FlowDestination : NavKey {
    @Serializable data object Camera : FlowDestination

    /** The bilan: it replaces the camera, which is what releases the lens. */
    @Serializable data class Tally(val addedBookCount: Int) : FlowDestination

    /** The sorting surface. Its way out is the cross, never back to a receipt (ADR 0007, rule 6). */
    @Serializable data object Sorting : FlowDestination

    /** An étagère as it will be — an existing one by its server id, or a draft by its client id. */
    @Serializable data class SortShelf(val shelfId: String?, val draftId: String?) : FlowDestination {
        val sectionId: SortSectionId
            get() = if (shelfId != null) SortSectionId.Shelf(shelfId) else SortSectionId.Draft(draftId.orEmpty())

        companion object {
            fun of(section: SortSectionId): SortShelf? = when (section) {
                is SortSectionId.Shelf -> SortShelf(shelfId = section.id, draftId = null)
                is SortSectionId.Draft -> SortShelf(shelfId = null, draftId = section.id)
                SortSectionId.Unshelved -> null
            }
        }
    }
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
    // A step that ends the one before it — the camera for the bilan, the bilan for the surface.
    val replaceAll: (NavKey) -> Unit = { destination ->
        backStack.clear()
        backStack.add(destination)
    }

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
                flowEntries(navigator = navigator, push = backStack::add, replaceAll = replaceAll, onClose = onClose)
                appEntries(navigator)
            },
        )
        SnackbarHost(snackbarHostState, Modifier.align(Alignment.BottomCenter).navigationBarsPadding()) { RecitSnackbar(it) }
    }
}

private fun rootOf(start: SortFlowStart): NavKey = when (start) {
    SortFlowStart.Scanning -> FlowDestination.Camera
    SortFlowStart.Sorting -> FlowDestination.Sorting
}

private fun EntryProviderScope<NavKey>.flowEntries(
    navigator: Navigator,
    push: (NavKey) -> Unit,
    replaceAll: (NavKey) -> Unit,
    onClose: () -> Unit,
) {
    entry<FlowDestination.Camera> {
        ScanCameraScreen(
            onOpenBook = { book -> navigator.push(Destination.Book(BookAnchor.Edition(book.uri))) },
            onFinished = { addedBookCount, presentsTally ->
                if (presentsTally) replaceAll(FlowDestination.Tally(addedBookCount)) else onClose()
            },
        )
    }
    entry<FlowDestination.Tally> { destination ->
        ScanTallyScreen(
            addedBookCount = destination.addedBookCount,
            onSort = { replaceAll(FlowDestination.Sorting) },
            onClose = onClose,
        )
    }
    entry<FlowDestination.Sorting> {
        SortSurfaceScreen(
            onClose = onClose,
            onOpenSection = { section -> FlowDestination.SortShelf.of(section)?.let(push) },
        )
    }
    entry<FlowDestination.SortShelf> { destination ->
        SortShelfScreen(sectionId = destination.sectionId, onBack = navigator::pop)
    }
}
