package studio.lunabee.exlibris.backend.groups

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class GroupRequestRoutesTest {
    @Test
    fun `a request lands under requested, and an admin accepting it makes a member`() =
        authTest {
            val admin: Reader = client.newReader()
            val requester: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)

            val request: HttpResponse = client.groupAction(requester, "request", groupId)

            assertMatchesFixture("auth/ok.derived.json", request.bodyAsText())
            assertEquals(listOf(requester.id), client.groupById(groupId).usersIn("requested"))

            val accept: HttpResponse = client.groupAction(admin, "accept-request", groupId, requester)

            assertMatchesFixture("auth/ok.derived.json", accept.bodyAsText())
            val group: JsonObject = client.groupById(groupId)
            assertEquals(listOf(requester.id), group.usersIn("members"))
            assertEquals(emptyList(), group.usersIn("requested"))
        }

    @Test
    fun `a plain member cannot accept a request`() =
        authTest {
            val admin: Reader = client.newReader()
            val member: Reader = client.newReader()
            val requester: Reader = client.newReader()
            val groupId: String = client.newGroup(admin, open = true)
            client.groupAction(member, "request", groupId)
            client.updateGroup(admin, groupId, "open", "false")
            client.groupAction(requester, "request", groupId)

            val accept: HttpResponse = client.groupAction(member, "accept-request", groupId, requester)

            assertEquals(HttpStatusCode.Forbidden, accept.status)
            assertMatchesFixture("groups/accept-request.not-admin.derived.json", accept.bodyAsText())
            assertEquals(listOf(requester.id), client.groupById(groupId).usersIn("requested"))
        }

    @Test
    fun `a request refused, or cancelled by its sender, is gone`() =
        authTest {
            val admin: Reader = client.newReader()
            val refused: Reader = client.newReader()
            val cancelling: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)
            client.groupAction(refused, "request", groupId)
            client.groupAction(cancelling, "request", groupId)

            val refuse: HttpResponse = client.groupAction(admin, "refuse-request", groupId, refused)
            val cancel: HttpResponse = client.groupAction(cancelling, "cancel-request", groupId)

            assertMatchesFixture("auth/ok.derived.json", refuse.bodyAsText())
            assertMatchesFixture("auth/ok.derived.json", cancel.bodyAsText())
            val group: JsonObject = client.groupById(groupId)
            assertEquals(emptyList(), group.usersIn("requested"))
            assertEquals(emptyList(), group.usersIn("members"))
        }

    @Test
    fun `an open group lets a request straight in`() =
        authTest {
            val admin: Reader = client.newReader()
            val reader: Reader = client.newReader()
            val groupId: String = client.newGroup(admin, open = true)

            client.groupAction(reader, "request", groupId)

            assertEquals(listOf(reader.id), client.groupById(groupId).usersIn("members"))
        }

    @Test
    fun `request refusals keep inventaire's words`() =
        authTest {
            val admin: Reader = client.newReader()
            val stranger: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)

            val alreadyIn: HttpResponse = client.groupAction(admin, "request", groupId)
            val noRequest: HttpResponse = client.groupAction(stranger, "cancel-request", groupId)
            val nothingToAccept: HttpResponse = client.groupAction(admin, "accept-request", groupId, stranger)

            assertEquals(HttpStatusCode.Forbidden, alreadyIn.status)
            assertMatchesFixture("groups/request.already-in-group.derived.json", alreadyIn.bodyAsText())
            assertEquals(HttpStatusCode.Forbidden, noRequest.status)
            assertMatchesFixture("groups/cancel-request.not-found.derived.json", noRequest.bodyAsText())
            assertEquals(HttpStatusCode.Unauthorized, nothingToAccept.status)
            assertMatchesFixture("groups/accept-request.not-requested.derived.json", nothingToAccept.bodyAsText())
        }
}
