package studio.lunabee.nouveaurecit.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
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

    @Test
    fun a_link_opens_the_tab_it_names_with_the_field_down() {
        val router = TabRouter(selected = AppTab.Lists)
        val landing: LinkLanding? = router.openLink(LinkTarget.Screen(AppTab.Search, Destination.Author("wd:Q535")))
        assertEquals(LinkLanding.OnTab(AppTab.Search, Destination.Author("wd:Q535")), landing)
        assertEquals(AppTab.Search, router.selected)
        assertFalse(router.consumeSearchField())
    }

    @Test
    fun a_link_opened_over_the_profile_goes_in_the_dialog_and_keeps_the_profile_up() {
        val router = TabRouter(selected = AppTab.Lists, isProfilePresented = true)
        val target = LinkTarget.Screen(AppTab.Lists, Destination.EntityList("l1"))
        assertEquals(LinkLanding.InDialog(target), router.openLink(target))
        assertTrue(router.isProfilePresented)
        assertEquals(AppTab.Lists, router.selected)
    }

    @Test
    fun a_link_opened_over_an_overlay_goes_in_the_dialog_and_leaves_the_tabs_alone() {
        val router = TabRouter(selected = AppTab.Inventory)
        router.overlayShown()
        val target = LinkTarget.Screen(AppTab.Network, Destination.User("reader"))
        assertEquals(LinkLanding.InDialog(target), router.openLink(target))
        assertEquals(AppTab.Inventory, router.selected)
    }

    @Test
    fun once_the_overlay_has_gone_a_link_is_pushed_on_its_tab_again() {
        val router = TabRouter()
        router.overlayShown()
        router.overlayHidden()
        val target = LinkTarget.Screen(AppTab.Network, Destination.User("reader"))
        assertEquals(LinkLanding.OnTab(AppTab.Network, Destination.User("reader")), router.openLink(target))
        assertEquals(AppTab.Network, router.selected)
    }

    @Test
    fun my_own_name_opens_the_profile_and_pushes_nothing() {
        val router = TabRouter(selected = AppTab.Lists)
        assertNull(router.openLink(LinkTarget.Profile))
        assertTrue(router.isProfilePresented)
        assertEquals(AppTab.Lists, router.selected)
    }

    @Test
    fun my_own_name_over_an_overlay_opens_the_profile_in_the_dialog() {
        val router = TabRouter()
        router.overlayShown()
        assertEquals(LinkLanding.InDialog(LinkTarget.Profile), router.openLink(LinkTarget.Profile))
        assertFalse(router.isProfilePresented)
    }

    @Test
    fun my_own_name_with_the_profile_up_opens_nothing_more() {
        val router = TabRouter(isProfilePresented = true)
        assertNull(router.openLink(LinkTarget.Profile))
        assertTrue(router.isProfilePresented)
    }
}
