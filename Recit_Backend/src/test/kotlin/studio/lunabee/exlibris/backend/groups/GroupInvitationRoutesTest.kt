package studio.lunabee.exlibris.backend.groups

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class GroupInvitationRoutesTest {
    @Test
    fun `an invitation from a member lands under invited, and accepting it makes a member`() =
        authTest {
            val admin: Reader = client.newReader()
            val invited: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)

            val invite: HttpResponse = client.groupAction(admin, "invite", groupId, invited)

            assertEquals(HttpStatusCode.OK, invite.status, invite.bodyAsText())
            assertMatchesFixture("auth/ok.derived.json", invite.bodyAsText())
            val pending: JsonObject = client.groupById(groupId)
            assertEquals(listOf(invited.id), pending.usersIn("invited"))
            assertEquals(
                admin.id,
                pending
                    .getValue("invited")
                    .jsonArray[0]
                    .jsonObject
                    .getValue("invitor")
                    .jsonPrimitive.content,
            )

            val accept: HttpResponse = client.groupAction(invited, "accept", groupId)

            assertMatchesFixture("auth/ok.derived.json", accept.bodyAsText())
            val joined: JsonObject = client.groupById(groupId)
            assertEquals(listOf(invited.id), joined.usersIn("members"))
            assertEquals(emptyList(), joined.usersIn("invited"))
        }

    @Test
    fun `an invitation declined lands under declined, and cannot be sent again`() =
        authTest {
            val admin: Reader = client.newReader()
            val invited: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)
            client.groupAction(admin, "invite", groupId, invited)

            val decline: HttpResponse = client.groupAction(invited, "decline", groupId)
            val again: HttpResponse = client.groupAction(admin, "invite", groupId, invited)

            assertMatchesFixture("auth/ok.derived.json", decline.bodyAsText())
            assertEquals(listOf(invited.id), client.groupById(groupId).usersIn("declined"))
            assertEquals(HttpStatusCode.BadRequest, again.status)
            assertMatchesFixture("groups/invite.declined.derived.json", again.bodyAsText())
        }

    @Test
    fun `any member may invite, and inviting a reader who asked lets them in`() =
        authTest {
            val admin: Reader = client.newReader()
            val member: Reader = client.newReader()
            val requester: Reader = client.newReader()
            val groupId: String = client.newGroup(admin, open = true)
            client.groupAction(member, "request", groupId)
            client.updateGroup(admin, groupId, "open", "false")
            client.groupAction(requester, "request", groupId)

            client.groupAction(member, "invite", groupId, requester)

            assertEquals(listOf(member.id, requester.id), client.groupById(groupId).usersIn("members"))
        }

    @Test
    fun `invitation refusals keep inventaire's words`() =
        authTest {
            val admin: Reader = client.newReader()
            val outsider: Reader = client.newReader()
            val member: Reader = client.newReader()
            val groupId: String = client.newGroup(admin, open = true)
            client.groupAction(member, "request", groupId)

            val notInGroup: HttpResponse = client.groupAction(outsider, "invite", groupId, admin)
            val unknown: HttpResponse =
                client.putJson(
                    admin,
                    "/api/groups/invite",
                    """{"group":"$groupId","user":"00000000000000000000000000000001"}""",
                )
            val existing: HttpResponse = client.groupAction(admin, "invite", groupId, member)
            val noInvitation: HttpResponse = client.groupAction(outsider, "accept", groupId)
            val missingUser: HttpResponse = client.putJson(admin, "/api/groups/invite", """{"group":"$groupId"}""")
            val noGroup: HttpResponse =
                client.putJson(admin, "/api/groups/leave", """{"group":"00000000000000000000000000000001"}""")
            val invalidGroup: HttpResponse = client.putJson(admin, "/api/groups/leave", """{"group":"nope"}""")
            val anonymous: HttpResponse =
                client.groupAction(Reader(AuthTestEnvironment.newAccount(), "", emptyMap()), "leave", groupId)

            assertEquals(HttpStatusCode.Forbidden, notInGroup.status)
            assertMatchesFixture("groups/invite.not-in-group.derived.json", notInGroup.bodyAsText())
            assertEquals(HttpStatusCode.NotFound, unknown.status)
            assertMatchesFixture("groups/invite.unknown-user.derived.json", unknown.bodyAsText())
            assertEquals(HttpStatusCode.OK, existing.status)
            assertMatchesFixture("groups/membership-exists.derived.json", existing.bodyAsText())
            assertEquals(HttpStatusCode.Forbidden, noInvitation.status)
            assertMatchesFixture("groups/membership-not-found.derived.json", noInvitation.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, missingUser.status)
            assertEquals("missing_user", missingUser.errorName())
            assertEquals(HttpStatusCode.NotFound, noGroup.status)
            assertMatchesFixture("groups/by-id.not-found.json", noGroup.bodyAsText())
            assertEquals("invalid_group", invalidGroup.errorName())
            assertEquals(HttpStatusCode.Unauthorized, anonymous.status)
            assertMatchesFixture("groups/groups.anonymous.json", anonymous.bodyAsText())
        }
}
