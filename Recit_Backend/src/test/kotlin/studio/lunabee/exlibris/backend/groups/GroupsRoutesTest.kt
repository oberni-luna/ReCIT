package studio.lunabee.exlibris.backend.groups

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GroupsRoutesTest {
    @Test
    fun `a group created appears in GET groups with its creator as admin, and by-id shows its slug`() =
        authTest {
            val creator: Reader = client.newReader()
            val name: String = uniqueGroupName("Club de lecture")

            val created: HttpResponse =
                client.postGroup(creator, """{"name":"$name","description":"","searchable":true,"open":false}""")

            assertEquals(HttpStatusCode.Created, created.status, created.bodyAsText())
            assertMatchesFixture("groups/create.derived.json", created.bodyAsText())
            val groupId: String =
                created
                    .json()
                    .getValue("_id")
                    .jsonPrimitive.content
            val mine: HttpResponse = client.getAs("/api/groups", creator)
            assertMatchesFixture("groups/groups.derived.json", mine.bodyAsText())
            val group: JsonObject =
                mine
                    .json()
                    .getValue("groups")
                    .jsonArray
                    .single()
                    .jsonObject
            assertEquals(groupId, group.getValue("_id").jsonPrimitive.content)
            assertEquals(listOf(creator.id), group.usersIn("admins"))
            assertEquals(JsonNull, group.getValue("admins").jsonArray[0].jsonObject["invitor"])
            assertEquals(
                GroupSlug.of(name),
                client
                    .groupById(groupId)
                    .getValue("slug")
                    .jsonPrimitive.content,
            )
        }

    @Test
    fun `by-id answers the group and its admins and members as users, in inventaire's shape`() =
        authTest {
            val admin: Reader = client.newReader()
            val member: Reader = client.newReader()
            val groupId: String = client.newGroup(admin, open = true)
            client.groupAction(member, "request", groupId)
            client.updateGroup(admin, groupId, "picture", "\"/img/groups/${"a".repeat(PICTURE_HASH_LENGTH)}\"")
            client.updateGroup(admin, groupId, "position", "[48.85,2.35]")

            val response: HttpResponse = client.getAs("/api/groups/by-id?id=$groupId", null)

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("groups/by-id.json", response.bodyAsText())
            val body: JsonObject = response.json()
            val captured: JsonObject = fixture("groups/by-id.members.json")
            val group: JsonObject = body.getValue("group").jsonObject
            val capturedGroup: JsonObject = captured.getValue("group").jsonObject
            assertMatchesShape(capturedGroup, group, "a group with members and a position")
            assertMatchesShape(
                capturedGroup.getValue("members").jsonArray[0].jsonObject,
                group.getValue("members").jsonArray[0].jsonObject,
                "a membership",
            )
            val users: JsonArray = body.getValue("users").jsonArray
            assertEquals(
                setOf(admin.id, member.id),
                users
                    .map {
                        it.jsonObject
                            .getValue("_id")
                            .jsonPrimitive.content
                    }.toSet(),
            )
            assertTrue(users.all { "email" !in it.jsonObject })
        }

    @Test
    fun `GET groups lists invitations but not requests`() =
        authTest {
            val admin: Reader = client.newReader()
            val invited: Reader = client.newReader()
            val requester: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)
            client.groupAction(admin, "invite", groupId, invited)
            client.groupAction(requester, "request", groupId)

            assertEquals(listOf(groupId), myGroupIds(invited))
            assertEquals(emptyList(), myGroupIds(requester))
        }

    @Test
    fun `creation reads inventaire's defaults and refuses an invalid name`() =
        authTest {
            val creator: Reader = client.newReader()

            val defaults: JsonObject = client.postGroup(creator, """{"name":"${uniqueGroupName()}"}""").json()
            val invalid: HttpResponse = client.postGroup(creator, """{"name":"2024"}""")
            val missing: HttpResponse = client.postGroup(creator, "{}")

            assertEquals(
                true,
                defaults
                    .getValue("searchable")
                    .jsonPrimitive.content
                    .toBoolean(),
            )
            assertEquals(
                false,
                defaults
                    .getValue("open")
                    .jsonPrimitive.content
                    .toBoolean(),
            )
            assertEquals("", defaults.getValue("description").jsonPrimitive.content)
            assertEquals(HttpStatusCode.BadRequest, invalid.status)
            assertMatchesFixture("groups/update-settings.invalid-name.derived.json", invalid.bodyAsText())
            assertEquals(
                "missing_name",
                missing
                    .json()
                    .getValue("error_name")
                    .jsonPrimitive.content,
            )
        }

    @Test
    fun `a second group of the same name gets the next slug`() =
        authTest {
            val creator: Reader = client.newReader()
            val name: String = uniqueGroupName()

            val first: String = client.newGroup(creator, name)
            val second: String = client.newGroup(creator, name)

            assertEquals(
                GroupSlug.of(name),
                client
                    .groupById(first)
                    .getValue("slug")
                    .jsonPrimitive.content,
            )
            assertEquals(
                "${GroupSlug.of(name)}.1",
                client
                    .groupById(second)
                    .getValue("slug")
                    .jsonPrimitive.content,
            )
        }

    @Test
    fun `refusals keep inventaire's words`() =
        authTest {
            val reader: Reader = client.newReader()

            val anonymous: HttpResponse = client.getAs("/api/groups", null)
            val notFound: HttpResponse = client.getAs("/api/groups/by-id?id=00000000000000000000000000000001", null)
            val invalid: HttpResponse = client.getAs("/api/groups/by-id?id=nope", null)
            val missing: HttpResponse = client.getAs("/api/groups/by-id", null)
            val anonymousCreation: HttpResponse =
                client.postGroup(Reader(reader.account, "", emptyMap()), """{"name":"x"}""")

            assertEquals(HttpStatusCode.Unauthorized, anonymous.status)
            assertMatchesFixture("groups/groups.anonymous.json", anonymous.bodyAsText())
            assertEquals(HttpStatusCode.NotFound, notFound.status)
            assertMatchesFixture("groups/by-id.not-found.json", notFound.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, invalid.status)
            assertMatchesFixture("groups/by-id.invalid-id.json", invalid.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, missing.status)
            assertMatchesFixture("groups/by-id.missing-id.json", missing.bodyAsText())
            assertEquals(HttpStatusCode.Unauthorized, anonymousCreation.status)
        }

    private suspend fun ApplicationTestBuilder.myGroupIds(reader: Reader): List<String> =
        client
            .getAs("/api/groups", reader)
            .json()
            .getValue("groups")
            .jsonArray
            .map {
                it.jsonObject
                    .getValue("_id")
                    .jsonPrimitive.content
            }

    private companion object {
        const val PICTURE_HASH_LENGTH: Int = 40
    }
}
