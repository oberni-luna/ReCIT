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
}
