package studio.lunabee.nouveaurecit.data.groups

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.GroupDto

/**
 * `ReaderGroupTests`: a group decoded from what inventaire.io actually sends, and where each person
 * stands in it.
 */
class ReaderGroupTest {
    /** A live `/api/groups/by-id` document, trimmed: an admin created it, nobody invited them. */
    private val liveJson: String = """
        {"_id":"g1","_rev":"2-cf0c","type":"group","name":"Le Club de lecture",
         "admins":[{"user":"admin","invitor":null,"timestamp":1445431103207}],
         "members":[],"invited":[],"declined":[],"requested":[],
         "creator":"admin","created":1445431103207,"searchable":true,"slug":"le-club-de-lecture","open":false}
    """.trimIndent()

    @Test
    fun aLiveDocumentDecodesANullInvitorIncluded() {
        val group: ReaderGroup = ReaderGroup.of(ApiService.DefaultJson.decodeFromString(GroupDto.serializer(), liveJson))
        assertEquals("Le Club de lecture", group.name)
        assertNull(group.admins.first().invitor)
        assertEquals(GroupRole.Admin, group.role(of = "admin"))
        assertFalse(group.open)
        assertEquals(1, group.memberCount)
        assertEquals("le-club-de-lecture", group.slug)
    }

    @Test
    fun aSparseDocumentTakesTheServersDefaults() {
        val dto: GroupDto = ApiService.DefaultJson.decodeFromString(GroupDto.serializer(), """{"_id":"g","name":"Old","admins":[],"members":[]}""")
        val group: ReaderGroup = ReaderGroup.of(dto)
        assertTrue(group.searchable)
        assertFalse(group.open)
        assertEquals("", group.description)
        assertTrue(group.requested.isEmpty())
    }

    @Test
    fun eachListGivesItsRoleAndAStrangerHasNone() {
        val group: ReaderGroup = group(members = listOf("m"), invited = listOf("i"), declined = listOf("d"), requested = listOf("r"))
        assertEquals(GroupRole.Admin, group.role(of = "admin"))
        assertEquals(GroupRole.Member, group.role(of = "m"))
        assertEquals(GroupRole.Invited, group.role(of = "i"))
        assertEquals(GroupRole.Declined, group.role(of = "d"))
        assertEquals(GroupRole.Requested, group.role(of = "r"))
        assertNull(group.role(of = "stranger"))
        assertNull(group.role(of = null))
    }

    @Test
    fun requestsToJoinWaitOnTheAdminsAndOnNobodyElse() {
        val group: ReaderGroup = group(members = listOf("m"), requested = listOf("r1", "r2"))
        assertEquals(2, group.requestsToReview(by = "admin"))
        assertEquals(0, group.requestsToReview(by = "m"))
        assertEquals(0, group.requestsToReview(by = null))
        assertEquals(0, group().requestsToReview(by = "admin"))
    }

    @Test
    fun everyoneNamedIncludesTheInvitors() {
        val group: ReaderGroup = group().copy(invited = listOf(GroupMembership(user = "i", invitor = "friend")))
        assertEquals(setOf("admin", "i", "friend"), group.everyoneIds)
        assertEquals("friend", group.invitor(of = "i"))
    }

    @Test
    fun theOnlyAdminCannotLeaveWhileMembersRemain() {
        assertFalse(group(members = listOf("m")).canLeave("admin"))
        assertTrue(group().canLeave("admin"))
        assertTrue(group(admins = listOf("admin", "b"), members = listOf("m")).canLeave("admin"))
        assertTrue(group(members = listOf("m")).canLeave("m"))
    }
}
