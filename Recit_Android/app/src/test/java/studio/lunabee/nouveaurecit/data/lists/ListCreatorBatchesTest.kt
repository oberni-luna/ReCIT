package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** `NetworkListsTests`: every friend's lists in one request per fifty friends. */
class ListCreatorBatchesTest {
    private fun friends(count: Int): List<String> = (1..count).map { "friend$it" }

    @Test
    fun no_friend_makes_no_request() {
        assertTrue(ListCreatorBatches.of(emptyList()).isEmpty())
    }

    @Test
    fun two_friends_make_one_request() {
        assertEquals(listOf(setOf("lea", "ines")), ListCreatorBatches.of(listOf("lea", "ines")))
    }

    @Test
    fun fifty_friends_per_request() {
        assertEquals(listOf(50), ListCreatorBatches.of(friends(50)).map { it.size })
        assertEquals(listOf(50, 50, 20), ListCreatorBatches.of(friends(120)).map { it.size })
    }

    @Test
    fun every_friend_is_asked_about_once() {
        val batches: List<Set<String>> = ListCreatorBatches.of(friends(51) + "friend1")
        assertEquals(friends(51).toSet(), batches.flatten().toSet())
        assertEquals(51, batches.sumOf { it.size })
    }
}
