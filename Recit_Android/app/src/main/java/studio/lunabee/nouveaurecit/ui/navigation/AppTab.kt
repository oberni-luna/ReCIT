package studio.lunabee.nouveaurecit.ui.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.automirrored.outlined.Assignment
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Book
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Search
import androidx.compose.ui.graphics.vector.ImageVector
import studio.lunabee.nouveaurecit.R

/**
 * `MainTabView.TabConfig`, in the tab bar's order. Transactions stays out, as it is hidden on iOS.
 * The Profil is not a tab any more: it opens from the avatar at the top left (feature 0038).
 * The selected icon is the filled variant, as `.symbolVariants(.fill)` does there.
 *
 * [hidesTabBarOnPush] is iOS's `hidesTabBarWhenPushed(on:)`, set once per stack (features 0088 and 0089):
 * every screen pushed in Inventaire, Listes and Réseau hides the tab bar, at any depth; Recherche keeps it.
 */
enum class AppTab(
    @StringRes val title: Int,
    val icon: ImageVector,
    val selectedIcon: ImageVector,
    val root: Destination,
    val hidesTabBarOnPush: Boolean,
) {
    Inventory(R.string.tab_inventory, Icons.Outlined.Book, Icons.Filled.Book, Destination.InventoryRoot, hidesTabBarOnPush = true),
    Lists(
        R.string.tab_lists,
        Icons.AutoMirrored.Outlined.Assignment,
        Icons.AutoMirrored.Filled.Assignment,
        Destination.ListsRoot,
        hidesTabBarOnPush = true,
    ),
    Network(R.string.tab_community, Icons.Outlined.People, Icons.Filled.People, Destination.NetworkRoot, hidesTabBarOnPush = true),

    /** Last, as iOS sets the search role apart at the bar's end (feature 0037). */
    Search(R.string.tab_search, Icons.Outlined.Search, Icons.Filled.Search, Destination.SearchRoot, hidesTabBarOnPush = false),
    ;

    /** Whether the tab bar shows over a screen of this tab: its root always, a pushed one unless the tab hides it. */
    fun showsTabBar(isAtRoot: Boolean): Boolean = isAtRoot || !hidesTabBarOnPush
}
