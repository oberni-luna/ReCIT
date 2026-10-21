package studio.lunabee.nouveaurecit.ui.navigation

import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * `Features/MainNavigation/TabRouter.swift`: what the shell shows, held in one place because
 * several screens ask for it — the selected tab, and whether the profile sheet is up (feature 0038).
 *
 * Plain Compose state, so it is driven by values in a JVM test. `MainScaffold` owns it and hands it
 * down through [LocalTabRouter].
 */
@Stable
class TabRouter(selected: AppTab = AppTab.Inventory, isProfilePresented: Boolean = false) {
    var selected: AppTab by mutableStateOf(selected)
        private set

    /** The profile sheet. Settable from outside: its « Fermer » and the system back lower it. */
    var isProfilePresented: Boolean by mutableStateOf(isProfilePresented)

    /**
     * A tap on [tab] in the bar. Returns whether it was the tab already showing, which sends that
     * tab back to its root — the caller owns the back stacks.
     */
    fun select(tab: AppTab): Boolean {
        val isReselection: Boolean = tab == selected
        selected = tab
        return isReselection
    }

    /** The avatar at the top left of Inventaire, Listes and Réseau. The tab behind does not change. */
    fun openProfile() {
        isProfilePresented = true
    }

    fun closeProfile() {
        isProfilePresented = false
    }

    companion object {
        /** Keeps the tab and the sheet across process death, as the back stacks are kept. */
        val Saver: Saver<TabRouter, Any> = listSaver(
            save = { listOf(it.selected.name, it.isProfilePresented) },
            restore = { TabRouter(AppTab.valueOf(it[0] as String), it[1] as Boolean) },
        )
    }
}

val LocalTabRouter = staticCompositionLocalOf<TabRouter> { error("No TabRouter provided") }
