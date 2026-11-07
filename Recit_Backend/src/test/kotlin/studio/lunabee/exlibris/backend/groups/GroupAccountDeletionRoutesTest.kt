package studio.lunabee.exlibris.backend.groups

import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.deleteAs
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class GroupAccountDeletionRoutesTest {
    @Test
    fun `deleting the account of a group's sole member deletes the group and its picture`() =
        authTest {
            val reader: Reader = client.newReader()
            val groupId: String = client.newGroup(reader)
            val picture: String = client.groupPicture(reader)
            client.updateGroup(reader, groupId, "picture", "\"$picture\"")

            assertEquals(HttpStatusCode.OK, client.deleteAs("/api/user", reader).status)

            assertEquals(HttpStatusCode.NotFound, client.getAs("/api/groups/by-id?id=$groupId", null).status)
            assertEquals(HttpStatusCode.NotFound, client.getAs(picture, null).status)
            assertEquals(
                0,
                AuthTestEnvironment.queryLong("SELECT count(*) FROM group_memberships WHERE group_id = '$groupId'"),
            )
        }

    @Test
    fun `a sole admin deleted leaves their three most senior members as admins, and the next as a member`() =
        authTest {
            val admin: Reader = client.newReader()
            val members: List<Reader> = List(SENIOR_COUNT + 1) { client.newReader() }
            val groupId: String = client.newGroup(admin, open = true)
            members.forEach { client.groupAction(it, "request", groupId) }

            client.deleteAs("/api/user", admin)

            val group: JsonObject = client.groupById(groupId)
            assertEquals(members.take(SENIOR_COUNT).map { it.id }, group.usersIn("admins"))
            assertEquals(listOf(members.last().id), group.usersIn("members"))
        }

    private companion object {
        /** inventaire.io's `removeUserFromGroupDoc` promotes three. Five sign-ups is a test's per-IP limit. */
        const val SENIOR_COUNT: Int = 3
    }
}
