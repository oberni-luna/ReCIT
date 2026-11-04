package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.network.dto.ListDto

/** `FriendListsTests`: a friend's lists live in the same store as mine, told apart by their creator. */
class ListSyncPlanTest {
    private fun stored(id: String, creator: String?): EntityListEntity = EntityListEntity(id = id, name = id, creatorId = creator)

    private fun answered(id: String, creator: String?): ListDto = ListDto(id = id, name = id, creator = creator)

    @Test
    fun the_creator_the_answer_names_is_stored() {
        val plan: ListSyncPlan = ListSyncPlan.plan(emptyList(), listOf(answered("a", "friend")), setOf("friend"), claimsUnstamped = false)
        assertEquals(listOf("friend"), plan.upserts.map { it.creatorId })
    }

    @Test
    fun a_list_the_answer_does_not_stamp_takes_the_sole_creator_asked_for() {
        val plan: ListSyncPlan = ListSyncPlan.plan(emptyList(), listOf(answered("a", null)), setOf("friend"), claimsUnstamped = false)
        assertEquals(listOf("friend"), plan.upserts.map { it.creatorId })
    }

    @Test
    fun a_friends_sync_prunes_their_lists_and_keeps_mine_stamped_or_not() {
        val existing: List<EntityListEntity> = listOf(
            stored("mine", "me"),
            stored("old", null),
            stored("kept", "friend"),
            stored("gone", "friend"),
            stored("other", "someone"),
        )
        val plan: ListSyncPlan = ListSyncPlan.plan(existing, listOf(answered("kept", "friend")), setOf("friend"), claimsUnstamped = false)
        assertEquals(listOf("gone"), plan.deletions)
    }

    @Test
    fun my_sync_claims_and_prunes_the_unstamped_lists_and_keeps_my_friends() {
        val existing: List<EntityListEntity> = listOf(
            stored("mine", "me"),
            stored("old", null),
            stored("stale", null),
            stored("friend", "friend"),
        )
        val plan: ListSyncPlan = ListSyncPlan.plan(
            existing,
            listOf(answered("mine", "me"), answered("old", null)),
            setOf("me"),
            claimsUnstamped = true,
        )
        assertEquals(listOf("stale"), plan.deletions)
        assertEquals(listOf("me", "me"), plan.upserts.map { it.creatorId })
    }

    @Test
    fun asked_about_several_readers_an_unstamped_answer_is_left_out() {
        val plan: ListSyncPlan = ListSyncPlan.plan(
            emptyList(),
            listOf(answered("a", "lea"), answered("b", null), answered("c", "stranger")),
            setOf("lea", "ines"),
            claimsUnstamped = false,
        )
        assertEquals(listOf("a"), plan.synced.map { it.id })
        assertEquals(listOf("a"), plan.upserts.map { it.id })
    }

    @Test
    fun a_network_batch_prunes_only_the_friends_it_asked_about() {
        val existing: List<EntityListEntity> = listOf(
            stored("mine", "me"),
            stored("old", null),
            stored("stranger", "someone"),
            stored("lea-kept", "lea"),
            stored("lea-gone", "lea"),
            stored("ines-gone", "ines"),
            stored("later", "zoe"),
        )
        val plan: ListSyncPlan = ListSyncPlan.plan(
            existing,
            listOf(answered("lea-kept", "lea"), answered("ines-new", "ines")),
            setOf("lea", "ines"),
            claimsUnstamped = false,
        )
        assertEquals(listOf("lea-gone", "ines-gone"), plan.deletions)
        assertEquals(listOf("lea", "ines"), plan.upserts.map { it.creatorId })
    }

    @Test
    fun a_sync_keeps_the_creator_stored_when_the_answer_omits_it() {
        val plan: ListSyncPlan = ListSyncPlan.plan(listOf(stored("a", "me")), listOf(answered("a", null)), setOf("me"), claimsUnstamped = true)
        assertEquals("me", plan.upserts.single().creatorId)
        assertNull(plan.deletions.firstOrNull())
    }
}
