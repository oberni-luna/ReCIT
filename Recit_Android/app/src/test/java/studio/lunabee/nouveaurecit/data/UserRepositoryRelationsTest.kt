package studio.lunabee.nouveaurecit.data

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.model.UserRelation

/** `UserRepositoryRelationsTest`: what a sync of `/api/relations` makes of the relations the store held. */
class UserRepositoryRelationsTest {
    @Test
    fun only_a_friendship_that_ends_is_ended() {
        val before: Map<String, UserRelation> = mapOf("a" to UserRelation.Friend, "b" to UserRelation.Friend, "c" to UserRelation.RequestSent)
        val after: Map<String, UserRelation> = mapOf("a" to UserRelation.None, "b" to UserRelation.Friend, "c" to UserRelation.None)
        assertEquals(setOf("a"), UserRepository.endedFriendships(before, after))
    }
}
