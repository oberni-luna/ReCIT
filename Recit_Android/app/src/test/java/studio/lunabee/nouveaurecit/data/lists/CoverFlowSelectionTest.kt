package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.lists.CoverFlowSelection.Result

class CoverFlowSelectionTest {
    @Test
    fun the_first_element_is_selected_when_nothing_is() {
        assertEquals(Result("a", null), CoverFlowSelection.next(emptyList(), listOf("a", "b"), null, null))
    }

    @Test
    fun the_selection_stays_on_its_uri() {
        assertEquals(Result("b", null), CoverFlowSelection.next(listOf("a", "b"), listOf("c", "a", "b"), "b", null))
    }

    @Test
    fun a_removed_element_hands_the_selection_to_the_one_in_its_place_or_the_last() {
        assertEquals(Result("c", null), CoverFlowSelection.next(listOf("a", "b", "c"), listOf("a", "c"), "b", null))
        assertEquals(Result("b", null), CoverFlowSelection.next(listOf("a", "b", "c"), listOf("a", "b"), "c", null))
        assertEquals(Result(null, null), CoverFlowSelection.next(listOf("a"), emptyList(), "a", null))
    }

    @Test
    fun the_uri_an_add_asked_for_waits_until_the_list_holds_it() {
        assertEquals(Result("a", "z"), CoverFlowSelection.next(listOf("a"), listOf("a"), "a", "z"))
        assertEquals(Result("z", null), CoverFlowSelection.next(listOf("a"), listOf("a", "z"), "a", "z"))
    }
}
