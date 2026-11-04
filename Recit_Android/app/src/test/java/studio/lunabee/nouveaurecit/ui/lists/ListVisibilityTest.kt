package studio.lunabee.nouveaurecit.ui.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.R
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
    fun each_answer_is_named_in_words_groups_included() {
        assertEquals(R.string.list_visibility_private, ListVisibility.from(emptyList()).label)
        assertEquals(R.string.list_visibility_groups, ListVisibility.from(listOf(Visibility.Groups)).label)
        assertEquals(R.string.list_visibility_friends_and_groups, ListVisibility.from(listOf(Visibility.Friends, Visibility.Groups)).label)
        assertEquals(R.string.list_visibility_public, ListVisibility.from(listOf(Visibility.Groups, Visibility.Public)).label)
    }

    @Test
    fun only_me_is_written_as_no_key() {
        assertTrue(ListVisibility.Private.raw.isEmpty())
    }
}
