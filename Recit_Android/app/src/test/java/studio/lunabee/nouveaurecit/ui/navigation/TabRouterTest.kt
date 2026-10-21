package studio.lunabee.nouveaurecit.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TabRouterTest {
    @Test
    fun selecting_another_tab_is_not_a_reselection() {
        val router = TabRouter()
        assertFalse(router.select(AppTab.Lists))
        assertEquals(AppTab.Lists, router.selected)
    }

    @Test
    fun tapping_the_tab_already_showing_is_a_reselection() {
        val router = TabRouter(selected = AppTab.Network)
        assertTrue(router.select(AppTab.Network))
        assertEquals(AppTab.Network, router.selected)
    }

    @Test
    fun opening_the_profile_keeps_the_tab_behind_it() {
        val router = TabRouter(selected = AppTab.Lists)
        router.openProfile()
        assertTrue(router.isProfilePresented)
        assertEquals(AppTab.Lists, router.selected)
        router.closeProfile()
        assertFalse(router.isProfilePresented)
    }

    @Test
    fun tapping_recherche_while_it_shows_raises_its_field_once() {
        val router = TabRouter(selected = AppTab.Search)
        assertTrue(router.select(AppTab.Search))
        assertTrue(router.consumeSearchField())
        assertFalse(router.consumeSearchField())
    }

    @Test
    fun arriving_on_recherche_leaves_the_keyboard_down() {
        val router = TabRouter()
        router.select(AppTab.Search)
        assertFalse(router.consumeSearchField())
    }

    @Test
    fun opening_the_search_selects_it_at_its_root_with_its_field_and_lowers_the_profile() {
        val router = TabRouter(isProfilePresented = true)
        router.openSearch()
        assertEquals(AppTab.Search, router.selected)
        assertEquals(1, router.searchRootRequest)
        assertTrue(router.consumeSearchField())
        assertFalse(router.isProfilePresented)
    }

    @Test
    fun opening_the_network_lowers_the_profile() {
        val router = TabRouter(selected = AppTab.Search, isProfilePresented = true)
        router.openNetwork()
        assertEquals(AppTab.Network, router.selected)
        assertFalse(router.isProfilePresented)
    }
}
