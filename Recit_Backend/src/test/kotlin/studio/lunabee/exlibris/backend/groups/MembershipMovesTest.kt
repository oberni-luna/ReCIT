package studio.lunabee.exlibris.backend.groups

import kotlin.test.Test
import kotlin.test.assertEquals

class MembershipMovesTest {
    @Test
    fun `a departing admin who was the only one hands the group to the three most senior members`() {
        val group: GroupRecord =
            group(
                GroupMembership("admin", GroupRole.ADMIN, invitor = null, timestamp = 1),
                GroupMembership("late", GroupRole.MEMBER, invitor = null, timestamp = 50),
                GroupMembership("first", GroupRole.MEMBER, invitor = null, timestamp = 10),
                GroupMembership("second", GroupRole.MEMBER, invitor = null, timestamp = 20),
                GroupMembership("third", GroupRole.MEMBER, invitor = null, timestamp = 30),
            )

        val changes: List<MembershipChange> = MembershipMoves.departure(group, "admin")

        assertEquals(
            listOf(
                MembershipChange.Remove("admin"),
                MembershipChange.Move("first", GroupRole.ADMIN),
                MembershipChange.Move("second", GroupRole.ADMIN),
                MembershipChange.Move("third", GroupRole.ADMIN),
            ),
            changes,
        )
    }

    @Test
    fun `a departing member leaves the admins as they are`() {
        val group: GroupRecord =
            group(
                GroupMembership("admin", GroupRole.ADMIN, invitor = null, timestamp = 1),
                GroupMembership("member", GroupRole.MEMBER, invitor = "admin", timestamp = 2),
            )

        assertEquals(listOf(MembershipChange.Remove("member")), MembershipMoves.departure(group, "member"))
    }

    private fun group(vararg memberships: GroupMembership): GroupRecord =
        GroupRecord(
            id = "group",
            version = 1,
            name = "Club",
            slug = "club",
            description = "",
            searchable = true,
            open = false,
            picture = null,
            position = null,
            creator = "admin",
            created = 1,
            memberships = memberships.toList(),
        )
}
