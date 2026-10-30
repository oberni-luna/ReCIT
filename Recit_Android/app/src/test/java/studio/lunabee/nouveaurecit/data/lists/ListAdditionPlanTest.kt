package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Test

/** `ListAdditionPlanTests`. */
class ListAdditionPlanTest {
    @Test
    fun what_the_list_lacks_is_added_in_the_order_chosen() {
        assertEquals(ListAdditionPlan.Add(listOf("c", "a")), ListAdditionPlan.plan(listOf("c", "b", "a", "c"), setOf("b")))
    }

    @Test
    fun a_list_holding_everything_shows_the_first_chosen() {
        assertEquals(ListAdditionPlan.AlreadyInList("b"), ListAdditionPlan.plan(listOf("b", "a"), setOf("a", "b")))
    }

    @Test
    fun nothing_chosen_is_nothing_to_do() {
        assertEquals(ListAdditionPlan.Nothing, ListAdditionPlan.plan(emptyList(), setOf("a")))
    }
}
