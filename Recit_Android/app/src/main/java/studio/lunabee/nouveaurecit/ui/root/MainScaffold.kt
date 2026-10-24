package studio.lunabee.nouveaurecit.ui.root

import android.content.Context
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.NavBackStack
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.ui.NavDisplay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.sorting.SortApplyFailure
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
import studio.lunabee.nouveaurecit.ui.navigation.LocalTabRouter
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.navigation.TabRouter
import studio.lunabee.nouveaurecit.ui.navigation.appEntries
import studio.lunabee.nouveaurecit.ui.profile.ProfileSheet

/**
 * `MainTabView`: a `NavigationBar` over the tabs, each owning its back stack — iOS's one
 * `NavigationStack(path:)` per tab. Switching tab keeps every stack where it was; re-selecting the
 * current tab pops it to its root, as tapping a selected tab does on iOS. The [TabRouter] says which
 * tab shows and whether the profile sheet is up over them (feature 0038).
 *
 * Failures reported by background writes, and every sentence a screen wants said, surface here once
 * as a snackbar — in the profile sheet while it is up, since it covers the shell's.
 *
 * The scan-and-sort flow (ADR 0007) is drawn here too, above the `Scaffold` — its navigation bar
 * included — and the snackbar moves above it while it is open.
 */
@Composable
fun MainScaffold() {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }
    val router: TabRouter = rememberSaveable(saver = TabRouter.Saver) { TabRouter() }
    val sortFlow: SortFlowPresentation = rememberSaveable(saver = sortFlowSaver) { SortFlowPresentation() }
    val flowStart: SortFlowStart? = sortFlow.start
    val stacks: Map<AppTab, NavBackStack<NavKey>> = AppTab.entries.associateWith { tab -> rememberNavBackStack(tab.root) }
    // Friend invitations, group invitations, and requests to join the groups I administer.
    val badgeCount: Flow<Int> = remember(container) {
        combine(container.users.receivedRequestCount, container.groups.pendingCount, Int::plus)
    }
    val badge: Int by badgeCount.collectAsState(initial = 0)
    val genericError: String = stringResource(R.string.error_generic)

    LaunchedEffect(Unit) {
        launch {
            container.errorReporter.failures.collect { error ->
                messenger.showError(genericError, failureMessage(context, error))
            }
        }
        messenger.messages.collect { message: SnackMessage ->
            snackbarHostState.currentSnackbarData?.dismiss()
            val result: SnackbarResult = snackbarHostState.showSnackbar(RecitSnackbarVisuals(message))
            if (result == SnackbarResult.ActionPerformed) message.onAction?.invoke()
        }
    }

    LaunchedEffect(router.searchRootRequest) {
        if (router.searchRootRequest > 0) Navigator(stacks.getValue(AppTab.Search)).popToRoot()
    }

    CompositionLocalProvider(LocalTabRouter provides router, LocalSortFlow provides sortFlow) {
        Box(Modifier.fillMaxSize()) {
            // Under an open flow the tabs are still composed, as on iOS, but out of reach of TalkBack.
            Box(if (flowStart == null) Modifier else Modifier.clearAndSetSemantics {}) {
                Shell(router, stacks, badge, snackbarHostState, showsSnackbar = flowStart == null)
            }
            if (flowStart != null) {
                SortFlowHost(start = flowStart, onClose = sortFlow::dismiss, snackbarHostState = snackbarHostState)
            }
            AnimatedVisibility(
                visible = router.isProfilePresented,
                enter = slideInVertically { it },
                exit = slideOutVertically { it },
            ) {
                ProfileSheet(onClose = router::closeProfile, snackbarHostState = snackbarHostState)
            }
        }
    }
}

@Composable
private fun Shell(
    router: TabRouter,
    stacks: Map<AppTab, NavBackStack<NavKey>>,
    badge: Int,
    snackbarHostState: SnackbarHostState,
    showsSnackbar: Boolean,
) {
    val selected: AppTab = router.selected
    Scaffold(
        contentWindowInsets = WindowInsets(0),
        snackbarHost = { if (showsSnackbar && !router.isProfilePresented) SnackbarHost(snackbarHostState) { RecitSnackbar(it) } },
        bottomBar = {
            NavigationBar(containerColor = RecitTheme.colors.backgroundSecondary) {
                AppTab.entries.forEach { tab ->
                    val isSelected: Boolean = tab == selected
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = {
                            if (router.select(tab)) Navigator(stacks.getValue(tab)).popToRoot()
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

/** What the snackbar says under « Une erreur s'est produite »: the sorting run names its étagère. */
private fun failureMessage(context: Context, error: Throwable): String? = when (error) {
    is SortApplyFailure.ShelfNoLongerExists -> context.getString(R.string.sort_error_shelf_missing, error.shelfName)
    is SortApplyFailure.BooksNoLongerInInventory -> context.getString(R.string.sort_error_books_missing, error.shelfName)
    else -> error.localizedMessage
}

/** The flow survives a configuration change at its start route; its own stack does not. */
private val sortFlowSaver: Saver<SortFlowPresentation, String> = Saver(
    save = { it.start?.name.orEmpty() },
    restore = { saved -> SortFlowPresentation(SortFlowStart.entries.firstOrNull { it.name == saved }) },
)
