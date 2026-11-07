package studio.lunabee.exlibris.backend.groups

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class GroupAdminRoutesTest {
    @Test
    fun `an admin makes a member admin, and kicks a member out`() =
        authTest {
            val admin: Reader = client.newReader()
            val promoted: Reader = client.newReader()
            val kicked: Reader = client.newReader()
            val groupId: String = groupWithMembers(admin, promoted, kicked)

            val makeAdmin: HttpResponse = client.groupAction(admin, "make-admin", groupId, promoted)
            val kick: HttpResponse = client.groupAction(admin, "kick", groupId, kicked)

            assertMatchesFixture("auth/ok.derived.json", makeAdmin.bodyAsText())
            assertMatchesFixture("auth/ok.derived.json", kick.bodyAsText())
            val group: JsonObject = client.groupById(groupId)
            assertEquals(listOf(admin.id, promoted.id), group.usersIn("admins"))
            assertEquals(emptyList(), group.usersIn("members"))
        }

    @Test
    fun `an admin cannot be kicked, and a plain member cannot kick or make admin`() =
        authTest {
            val admin: Reader = client.newReader()
            val other: Reader = client.newReader()
            val member: Reader = client.newReader()
            val groupId: String = groupWithMembers(admin, other, member)
            client.groupAction(admin, "make-admin", groupId, other)

            val kickAdmin: HttpResponse = client.groupAction(admin, "kick", groupId, other)
            val memberKick: HttpResponse = client.groupAction(member, "kick", groupId, admin)
            val memberPromotion: HttpResponse = client.groupAction(member, "make-admin", groupId, member)

            assertEquals(HttpStatusCode.Forbidden, kickAdmin.status)
            assertMatchesFixture("groups/kick.admin.derived.json", kickAdmin.bodyAsText())
            assertEquals(HttpStatusCode.Forbidden, memberKick.status)
            assertMatchesFixture("groups/not-admin.derived.json", memberKick.bodyAsText())
            assertEquals(HttpStatusCode.Forbidden, memberPromotion.status)
            assertMatchesFixture("groups/not-admin.derived.json", memberPromotion.bodyAsText())
            assertEquals(listOf(admin.id, other.id), client.groupById(groupId).usersIn("admins"))
        }

    @Test
    fun `the last admin leaves only once another is named`() =
        authTest {
            val admin: Reader = client.newReader()
            val member: Reader = client.newReader()
            val groupId: String = groupWithMembers(admin, member)

            val refused: HttpResponse = client.groupAction(admin, "leave", groupId)
            client.groupAction(admin, "make-admin", groupId, member)
            val allowed: HttpResponse = client.groupAction(admin, "leave", groupId)

            assertEquals(HttpStatusCode.Forbidden, refused.status)
            assertMatchesFixture("groups/leave.last-admin.derived.json", refused.bodyAsText())
            assertMatchesFixture("auth/ok.derived.json", allowed.bodyAsText())
            assertEquals(listOf(member.id), client.groupById(groupId).usersIn("admins"))
        }

    @Test
    fun `the last member leaving ends the group, and its picture`() =
        authTest {
            val admin: Reader = client.newReader()
            val invited: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)
            client.groupAction(admin, "invite", groupId, invited)
            val picture: String = client.groupPicture(admin)
            client.updateGroup(admin, groupId, "picture", "\"$picture\"")

            val leave: HttpResponse = client.groupAction(admin, "leave", groupId)

            assertMatchesFixture("auth/ok.derived.json", leave.bodyAsText())
            val byId: HttpResponse = client.getAs("/api/groups/by-id?id=$groupId", null)
            assertEquals(HttpStatusCode.NotFound, byId.status)
            assertMatchesFixture("groups/by-id.not-found.json", byId.bodyAsText())
            assertEquals(
                0,
                client
                    .getAs("/api/groups", invited)
                    .json()
                    .getValue("groups")
                    .jsonArray.size,
            )
            assertEquals(HttpStatusCode.NotFound, client.getAs(picture, null).status)
        }

    @Test
    fun `someone outside the group cannot leave it`() =
        authTest {
            val admin: Reader = client.newReader()
            val outsider: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)

            val leave: HttpResponse = client.groupAction(outsider, "leave", groupId)

            assertEquals(HttpStatusCode.Forbidden, leave.status)
            assertMatchesFixture("groups/leave.not-in-group.derived.json", leave.bodyAsText())
        }

    /** A closed group of [admin], [members] let in through requests their admin accepted. */
    private suspend fun ApplicationTestBuilder.groupWithMembers(
        admin: Reader,
        vararg members: Reader,
    ): String {
        val groupId: String = client.newGroup(admin)
        members.forEach { member ->
            client.groupAction(member, "request", groupId)
            client.groupAction(admin, "accept-request", groupId, member)
        }
        return groupId
    }
}
