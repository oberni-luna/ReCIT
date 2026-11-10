package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.data.lists.ListArrivalFocus.Move
import studio.lunabee.nouveaurecit.data.lists.ListArrivalFocus.Phase

/** `ListArrivalFocusTests`: the arrival of a list on the book it was opened from, played once. */
class ListArrivalFocusTest {
    private val uris: List<String> = listOf("wd:Q1", "wd:Q2")

    @Test
    fun scrolls_from_the_first_element_to_the_focused_one_then_rings_it_once_centred() {
        val arriving: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, selectedUri = null, reducesMotion = false)
        assertEquals(Phase.Arriving(Move.Scroll("wd:Q2")), arriving.phase)
        assertNull(arriving.highlightedUri)

        val landed: ListArrivalFocus = arriving.land("wd:Q2")
        assertEquals("wd:Q2", landed.highlightedUri)

        assertEquals(Phase.Done, landed.endHighlight().phase)
    }

    @Test
    fun does_nothing_for_a_list_opened_without_a_focus() {
        val arrival: ListArrivalFocus = ListArrivalFocus.on(null).start(uris, selectedUri = null, reducesMotion = false).land("wd:Q1")

        assertEquals(Phase.Done, arrival.phase)
        assertNull(arrival.highlightedUri)
    }

    @Test
    fun jumps_straight_to_the_focused_element_with_the_animations_off() {
        val arrival: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, selectedUri = null, reducesMotion = true)

        assertEquals(Phase.Arriving(Move.Jump("wd:Q2")), arrival.phase)
        assertEquals("wd:Q2", arrival.jumpUri)
    }

    @Test
    fun puts_the_halo_out_when_the_reader_picks_another_element() {
        val landed: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, "wd:Q1", reducesMotion = false).land("wd:Q2")

        assertEquals("wd:Q2", landed.select("wd:Q2").highlightedUri)
        assertEquals(Phase.Done, landed.select("wd:Q1").phase)
    }

    @Test
    fun rings_nothing_when_the_reader_moved_away_during_the_scroll() {
        val arrival: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, "wd:Q1", reducesMotion = false)

        assertEquals(arrival, arrival.select("wd:Q1"))
        assertEquals(Phase.Done, arrival.land("wd:Q1").phase)
    }

    @Test
    fun waits_for_the_list_to_hold_the_focused_element_then_arrives_once() {
        val waiting: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(emptyList(), selectedUri = null, reducesMotion = false)
        assertEquals(Phase.Waiting("wd:Q2"), waiting.phase)

        val arriving: ListArrivalFocus = waiting.start(uris, "wd:Q1", reducesMotion = false)
        assertEquals(Phase.Arriving(Move.Scroll("wd:Q2")), arriving.phase)

        val over: ListArrivalFocus = arriving.land("wd:Q2").endHighlight()
        assertEquals(Phase.Done, over.start(uris + "wd:Q3", "wd:Q2", reducesMotion = false).phase)
    }

    @Test
    fun leaves_the_haptic_to_the_cover_flow_when_the_scroll_moves_the_selection() {
        val landed: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, selectedUri = null, reducesMotion = false).land("wd:Q2")

        assertEquals("wd:Q2", landed.highlightedUri)
        assertNull(landed.landingFeedbackUri)
    }

    @Test
    fun ticks_as_the_halo_lights_when_the_focused_element_is_the_first() {
        val landed: ListArrivalFocus = ListArrivalFocus.on("wd:Q1").start(uris, selectedUri = null, reducesMotion = false).land("wd:Q1")

        assertEquals("wd:Q1", landed.landingFeedbackUri)
    }

    @Test
    fun ticks_as_the_halo_lights_after_a_jump_from_no_selection() {
        val landed: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, selectedUri = null, reducesMotion = true).land("wd:Q2")

        assertEquals("wd:Q2", landed.landingFeedbackUri)
    }

    @Test
    fun leaves_the_haptic_to_the_cover_flow_when_a_jump_moves_an_existing_selection() {
        val landed: ListArrivalFocus = ListArrivalFocus.on("wd:Q2").start(uris, "wd:Q1", reducesMotion = true).land("wd:Q2")

        assertNull(landed.landingFeedbackUri)
    }

    @Test
    fun the_halo_out_the_landing_haptic_goes_with_it() {
        val landed: ListArrivalFocus = ListArrivalFocus.on("wd:Q1").start(uris, selectedUri = null, reducesMotion = false).land("wd:Q1")

        assertNull(landed.select("wd:Q2").landingFeedbackUri)
    }
}
