package studio.lunabee.nouveaurecit.data.groups

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.GroupDto
import studio.lunabee.nouveaurecit.ui.network.groups.groupActionsHaveContent

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
        assertThrows(GroupTransitionError.LastAdmin::class.java) { group(members = listOf("m")).applying(GroupAction.Leave, by = "admin") }
        assertNull(group().applying(GroupAction.Leave, by = "admin").role(of = "admin"))
        assertNull(group(admins = listOf("admin", "b"), members = listOf("m")).applying(GroupAction.Leave, by = "admin").role(of = "admin"))
        assertNull(group(members = listOf("m")).applying(GroupAction.Leave, by = "m").role(of = "m"))
    }

    @Test
    fun aRequestToAGroupOnRequestWaitsAndToAnOpenGroupLetsYouIn() {
        assertEquals(GroupRole.Requested, group().applying(GroupAction.Request, by = "me").role(of = "me"))
        assertEquals(GroupRole.Member, group(open = true).applying(GroupAction.Request, by = "me").role(of = "me"))
    }

    @Test
    fun aRequestFromSomeoneInvitedOrWhoDeclinedLetsThemIn() {
        assertEquals(GroupRole.Member, group(invited = listOf("me")).applying(GroupAction.Request, by = "me").role(of = "me"))
        assertEquals(GroupRole.Member, group(declined = listOf("me")).applying(GroupAction.Request, by = "me").role(of = "me"))
        assertThrows(GroupTransitionError.AlreadyInGroup::class.java) { group(members = listOf("me")).applying(GroupAction.Request, by = "me") }
    }

    @Test
    fun anInvitationToSomeoneWhoHadAskedAcceptsThem() {
        assertEquals(GroupRole.Member, group(requested = listOf("r")).applying(GroupAction.Invite, by = "admin", on = "r").role(of = "r"))
    }

    @Test
    fun anInvitationRemembersWhoSentItAndCannotReachSomeoneWhoDeclined() {
        val invited: ReaderGroup = group().applying(GroupAction.Invite, by = "admin", on = "friend", at = 42.0)
        assertEquals(GroupRole.Invited, invited.role(of = "friend"))
        assertEquals("admin", invited.invitor(of = "friend"))
        assertEquals(42.0, invited.invited.single().timestamp)
        assertThrows(GroupTransitionError.AlreadyDeclined::class.java) { group(declined = listOf("d")).applying(GroupAction.Invite, by = "admin", on = "d") }
        assertThrows(GroupTransitionError.AlreadyInGroup::class.java) { group(members = listOf("m")).applying(GroupAction.Invite, by = "admin", on = "m") }
        assertThrows(GroupTransitionError.MissingTarget::class.java) { group().applying(GroupAction.Invite, by = "admin") }
    }

    @Test
    fun answeringAnInvitationMovesMeToMembersOrToDeclined() {
        assertEquals(GroupRole.Member, group(invited = listOf("me")).applying(GroupAction.Accept, by = "me").role(of = "me"))
        assertEquals(GroupRole.Declined, group(invited = listOf("me")).applying(GroupAction.Decline, by = "me").role(of = "me"))
        assertThrows(GroupTransitionError.NotInExpectedRole::class.java) { group().applying(GroupAction.Accept, by = "me") }
    }

    @Test
    fun cancellingARequestTakesMeOut() {
        assertNull(group(requested = listOf("me")).applying(GroupAction.CancelRequest, by = "me").role(of = "me"))
    }

    @Test
    fun theButtonsUnderAGroupsHeaderAreLeftOutOnlyForAMemberWhoMayLeave() {
        assertFalse(groupActionsHaveContent(GroupRole.Admin, canLeave = true))
        assertFalse(groupActionsHaveContent(GroupRole.Member, canLeave = true))
        // The only admin with members left: the note that says why « Quitter » is off.
        assertTrue(groupActionsHaveContent(GroupRole.Admin, canLeave = false))
        assertTrue(groupActionsHaveContent(null, canLeave = true))
        assertTrue(groupActionsHaveContent(GroupRole.Requested, canLeave = true))
        assertTrue(groupActionsHaveContent(GroupRole.Invited, canLeave = true))
    }
}
