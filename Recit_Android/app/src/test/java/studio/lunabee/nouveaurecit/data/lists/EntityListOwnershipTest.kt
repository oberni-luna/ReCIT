package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EntityListEntity

/** `EntityList.isCreated(byMe:)`. */
class EntityListOwnershipTest {
    private fun list(creator: String?): EntityListEntity = EntityListEntity(id = "list", name = "Liste", creatorId = creator)

    @Test
    fun an_unstamped_list_is_mine() {
        assertTrue(list(null).isCreatedByMe("me"))
    }

    @Test
    fun a_list_i_made_is_mine() {
        assertTrue(list("me").isCreatedByMe("me"))
    }

    @Test
    fun a_friends_list_is_not_mine() {
        assertFalse(list("friend").isCreatedByMe("me"))
    }

    @Test
    fun without_my_id_only_the_unstamped_lists_are_mine() {
        assertFalse(list("me").isCreatedByMe(null))
        assertTrue(list(null).isCreatedByMe(null))
    }
}
