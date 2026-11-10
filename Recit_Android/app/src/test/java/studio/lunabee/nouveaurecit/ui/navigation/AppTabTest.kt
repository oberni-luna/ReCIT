package studio.lunabee.nouveaurecit.ui.navigation

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AppTabTest {
    @Test
    fun every_tab_shows_the_tab_bar_at_its_root() {
        AppTab.entries.forEach { tab -> assertTrue(tab.name, tab.showsTabBar(isAtRoot = true)) }
    }

    @Test
    fun inventaire_listes_and_reseau_hide_the_tab_bar_on_a_pushed_screen() {
        listOf(AppTab.Inventory, AppTab.Lists, AppTab.Network).forEach { tab ->
            assertFalse(tab.name, tab.showsTabBar(isAtRoot = false))
        }
    }

    @Test
    fun recherche_keeps_the_tab_bar_on_a_pushed_screen() {
        assertTrue(AppTab.Search.showsTabBar(isAtRoot = false))
    }
}
