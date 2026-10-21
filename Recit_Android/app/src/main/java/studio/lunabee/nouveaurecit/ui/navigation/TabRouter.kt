package studio.lunabee.nouveaurecit.ui.navigation

import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * `Features/MainNavigation/TabRouter.swift`: what the shell shows, held in one place because
 * several screens ask for it — the selected tab, whether the profile sheet is up (feature 0038), and
 * what the Recherche tab has been asked for (feature 0037).
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
     * The Recherche tab is to raise its field. A flag rather than an event: the tab may not be
     * composed yet when the empty shelf asks, and the flag waits for it. See [consumeSearchField].
     */
    var wantsSearchField: Boolean by mutableStateOf(false)
        private set

    /** Bumped each time the Recherche tab is to go back to its root; the shell owns its stack. */
    var searchRootRequest: Int by mutableIntStateOf(0)
        private set

    /**
     * A tap on [tab] in the bar. Returns whether it was the tab already showing, which sends that
     * tab back to its root — the caller owns the back stacks. Tapping Recherche while it shows also
     * raises its field.
     */
    fun select(tab: AppTab): Boolean {
        val isReselection: Boolean = tab == selected
        selected = tab
        if (isReselection && tab == AppTab.Search) wantsSearchField = true
        return isReselection
    }

    /** The empty shelf's « Rechercher »: Recherche, at its root, its field raised. */
    fun openSearch() {
        selected = AppTab.Search
        searchRootRequest += 1
        wantsSearchField = true
        isProfilePresented = false
    }

    /** « Trouver des lecteurs », in Recherche for a reader with no friend: finding one lives in Réseau. */
    fun openNetwork() {
        selected = AppTab.Network
        isProfilePresented = false
    }

    /** Takes the field request, once: `true` when the Recherche tab is to focus its field now. */
    fun consumeSearchField(): Boolean {
        if (!wantsSearchField) return false
        wantsSearchField = false
        return true
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
