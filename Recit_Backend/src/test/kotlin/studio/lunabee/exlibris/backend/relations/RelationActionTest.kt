package studio.lunabee.exlibris.backend.relations

import kotlin.test.Test
import kotlin.test.assertEquals

class RelationActionTest {
    private val smaller: String = "0".repeat(32)
    private val larger: String = "f".repeat(32)

    @Test
    fun `each action moves only from the states inventaire moves it from`() {
        val expected: Map<RelationAction, Map<UserRelation, UserRelation>> =
            mapOf(
                RelationAction.REQUEST to
                    mapOf(
                        UserRelation.NONE to UserRelation.USER_REQUESTED,
                        UserRelation.OTHER_REQUESTED to UserRelation.FRIENDS,
                    ),
                RelationAction.CANCEL to mapOf(UserRelation.USER_REQUESTED to UserRelation.NONE),
                RelationAction.ACCEPT to mapOf(UserRelation.OTHER_REQUESTED to UserRelation.FRIENDS),
                RelationAction.DISCARD to mapOf(UserRelation.OTHER_REQUESTED to UserRelation.NONE),
                RelationAction.UNFRIEND to
                    mapOf(
                        UserRelation.FRIENDS to UserRelation.NONE,
                        UserRelation.USER_REQUESTED to UserRelation.NONE,
                        UserRelation.OTHER_REQUESTED to UserRelation.NONE,
                    ),
            )
        RelationAction.entries.forEach { action ->
            UserRelation.entries.forEach { current ->
                assertEquals(expected.getValue(action)[current], action.next(current), "$action from $current")
            }
        }
    }

    @Test
    fun `a request is stored about the pair and read back from either side`() {
        assertEquals(RelationStatus.A_REQUESTED, UserRelation.USER_REQUESTED.status(smaller, larger))
        assertEquals(RelationStatus.B_REQUESTED, UserRelation.USER_REQUESTED.status(larger, smaller))
        UserRelation.entries.forEach { relation ->
            val status: RelationStatus = relation.status(larger, smaller)
            assertEquals(relation, UserRelation.of(larger, smaller, status))
            val mirrored: UserRelation =
                when (relation) {
                    UserRelation.USER_REQUESTED -> UserRelation.OTHER_REQUESTED
                    UserRelation.OTHER_REQUESTED -> UserRelation.USER_REQUESTED
                    else -> relation
                }
            assertEquals(mirrored, UserRelation.of(smaller, larger, status))
        }
    }
}
