package studio.lunabee.nouveaurecit.ui.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.model.Visibility

class ListVisibilityTest {
    @Test
    fun keys_are_read_as_one_of_the_five_answers() {
        assertEquals(ListVisibility.Private, ListVisibility.from(emptyList()))
        assertEquals(ListVisibility.Friends, ListVisibility.from(listOf(Visibility.Friends)))
        assertEquals(ListVisibility.Groups, ListVisibility.from(listOf(Visibility.Groups)))
        assertEquals(ListVisibility.FriendsAndGroups, ListVisibility.from(listOf(Visibility.Groups, Visibility.Friends)))
        assertEquals(ListVisibility.Public, ListVisibility.from(listOf(Visibility.Friends, Visibility.Public, Visibility.Groups)))
    }

    @Test
    fun each_answer_is_written_as_the_keys_it_is_read_from() {
        ListVisibility.entries.forEach { assertEquals(it, ListVisibility.from(it.raw)) }
    }

    @Test
    fun only_me_is_written_as_no_key() {
        assertTrue(ListVisibility.Private.raw.isEmpty())
    }
}
