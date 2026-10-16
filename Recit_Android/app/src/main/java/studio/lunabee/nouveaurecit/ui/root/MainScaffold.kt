package studio.lunabee.nouveaurecit.ui.root

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitSnackbar
import studio.lunabee.nouveaurecit.ui.common.RecitSnackbarVisuals
import studio.lunabee.nouveaurecit.ui.common.SnackMessage
import studio.lunabee.nouveaurecit.ui.flow.LocalSortFlow
import studio.lunabee.nouveaurecit.ui.flow.SortFlowHost
import studio.lunabee.nouveaurecit.ui.flow.SortFlowPresentation
import studio.lunabee.nouveaurecit.ui.flow.SortFlowStart
import studio.lunabee.nouveaurecit.ui.navigation.AppTab
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.appEntries

/**
 * `MainTabView`: a `NavigationBar` over four tabs, each owning its back stack — iOS's one
 * `NavigationStack(path:)` per tab. Switching tab keeps every stack where it was; re-selecting the
 * current tab pops it to its root, as tapping a selected tab does on iOS.
 *
 * Failures reported by background writes, and every sentence a screen wants said, surface here once
 * as a snackbar.
 *
 * The scan-and-sort flow (ADR 0007) is drawn here too, above the `Scaffold` — its navigation bar
 * included — and the snackbar moves above it while it is open.
 */
@Composable
fun MainScaffold() {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
    var selected: AppTab by rememberSaveable { mutableStateOfTab() }
    val stacks: Map<AppTab, NavBackStack<NavKey>> = AppTab.entries.associateWith { tab -> rememberNavBackStack(tab.root) }
    val badge: Int by container.users.receivedRequestCount.collectAsState(initial = 0)
    val genericError: String = stringResource(R.string.error_generic)
    val sortFlow: SortFlowPresentation = rememberSaveable(saver = sortFlowSaver) { SortFlowPresentation() }
    val flowStart: SortFlowStart? = sortFlow.start

    LaunchedEffect(Unit) {
        launch {
            container.errorReporter.failures.collect { error ->
                messenger.showError(genericError, error.localizedMessage)
            }
        }
        messenger.messages.collect { message: SnackMessage ->
            snackbarHostState.currentSnackbarData?.dismiss()
            snackbarHostState.showSnackbar(RecitSnackbarVisuals(message))
        }
    }

    CompositionLocalProvider(LocalSortFlow provides sortFlow) {
        Box {
            // Under an open flow the tabs are still composed, as on iOS, but out of reach of TalkBack.
            Box(if (flowStart == null) Modifier else Modifier.clearAndSetSemantics {}) {
                Tabs(
                    selected = selected,
                    onSelect = { selected = it },
                    stacks = stacks,
                    badge = badge,
                    snackbarHostState = snackbarHostState,
                    showsSnackbar = flowStart == null,
                )
            }
            if (flowStart != null) {
                SortFlowHost(start = flowStart, onClose = sortFlow::dismiss, snackbarHostState = snackbarHostState)
            }
        }
    }
}

@Composable
private fun Tabs(
    selected: AppTab,
    onSelect: (AppTab) -> Unit,
    stacks: Map<AppTab, NavBackStack<NavKey>>,
    badge: Int,
    snackbarHostState: SnackbarHostState,
    showsSnackbar: Boolean,
) {
    Scaffold(
        contentWindowInsets = WindowInsets(0),
        snackbarHost = { if (showsSnackbar) SnackbarHost(snackbarHostState) { RecitSnackbar(it) } },
        bottomBar = {
            NavigationBar(containerColor = RecitTheme.colors.backgroundSecondary) {
                AppTab.entries.forEach { tab ->
                    val isSelected: Boolean = tab == selected
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = {
                            if (isSelected) Navigator(stacks.getValue(tab)).popToRoot() else onSelect(tab)
                        },
                        icon = {
                            BadgedBox(badge = { if (tab == AppTab.Network && badge > 0) Badge { Text("$badge") } }) {
                                Icon(if (isSelected) tab.selectedIcon else tab.icon, contentDescription = null)
                            }
                        },
                        label = { Text(stringResource(tab.title), style = RecitTheme.typography.action200) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = RecitTheme.colors.foregroundTinted,
                            selectedTextColor = RecitTheme.colors.foregroundTinted,
                            indicatorColor = RecitTheme.colors.backgroundTinted,
                            unselectedIconColor = RecitTheme.colors.foregroundSecondary,
                            unselectedTextColor = RecitTheme.colors.foregroundSecondary,
                        ),
                    )
                }
            }
        },
    ) { padding: PaddingValues ->
        Box(Modifier.padding(padding).consumeWindowInsets(padding)) {
            TabContent(stacks.getValue(selected))
        }
    }
}

@Composable
private fun TabContent(backStack: NavBackStack<NavKey>) {
    val navigator: Navigator = remember(backStack) { Navigator(backStack) }
    NavDisplay(
        backStack = backStack,
        onBack = { navigator.pop() },
        entryDecorators = listOf(
            rememberSaveableStateHolderNavEntryDecorator(),
            rememberViewModelStoreNavEntryDecorator(),
        ),
        entryProvider = entryProvider { appEntries(navigator) },
    )
}

private fun mutableStateOfTab() = androidx.compose.runtime.mutableStateOf(AppTab.Inventory)

/** The flow survives a configuration change at its start route; its own stack does not. */
private val sortFlowSaver: Saver<SortFlowPresentation, String> = Saver(
    save = { it.start?.name.orEmpty() },
    restore = { saved -> SortFlowPresentation(SortFlowStart.entries.firstOrNull { it.name == saved }) },
)
