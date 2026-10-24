package studio.lunabee.nouveaurecit.data.groups

import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.GroupSettingPayload
import studio.lunabee.nouveaurecit.ui.network.groups.InviteTrailing
import studio.lunabee.nouveaurecit.ui.network.groups.inviteTrailing

/** What an admin writes about a group, and what the forms let through. */
class GroupFormsTest {
    @Test
    fun aSettingIsWrittenOntoTheGroupAndTravelsAsAStringOrABoolean() {
        val renamed: ReaderGroup = GroupSetting.Name("Polars").applied(to = group())
        assertEquals("Polars", renamed.name)
        assertTrue(GroupSetting.Open(true).applied(to = group()).open)
        assertFalse(GroupSetting.Searchable(false).applied(to = group()).searchable)
        assertEquals("Le jeudi", GroupSetting.Description("Le jeudi").applied(to = group()).description)

        val json: String = ApiService.DefaultJson.encodeToString(
            GroupSettingPayload.serializer(),
            GroupSettingPayload(group = "g1", attribute = GroupSetting.Open(true).attribute, value = GroupSetting.Open(true).value),
        )
        assertEquals("""{"group":"g1","attribute":"open","value":true}""", json)
        assertEquals(JsonPrimitive("Polars"), GroupSetting.Name("Polars").value)
        assertEquals("name", GroupSetting.Name("Polars").attribute)
    }

    @Test
    fun aGroupNameIsOneToEightyCharactersOnceTrimmed() {
        assertFalse(GroupNameRule.accepts(""))
        assertFalse(GroupNameRule.accepts("   "))
        assertTrue(GroupNameRule.accepts(" Club "))
        assertTrue(GroupNameRule.accepts("a".repeat(80)))
        assertFalse(GroupNameRule.accepts("a".repeat(81)))
        assertTrue(GroupNameRule.isTooLong("a".repeat(81)))
        assertFalse(GroupNameRule.isTooLong("a".repeat(80)))
    }

    @Test
    fun aFriendsLineSaysWhereTheyStandAndInvitingSomeoneWhoAskedAcceptsThem() {
        assertEquals(InviteTrailing.AlreadyMember, inviteTrailing(GroupRole.Admin))
        assertEquals(InviteTrailing.AlreadyMember, inviteTrailing(GroupRole.Member))
        assertEquals(InviteTrailing.Sent, inviteTrailing(GroupRole.Invited))
        assertEquals(InviteTrailing.Declined, inviteTrailing(GroupRole.Declined))
        assertEquals(InviteTrailing.Accept, inviteTrailing(GroupRole.Requested))
        assertEquals(InviteTrailing.Invite, inviteTrailing(null))
    }
}
