package studio.lunabee.exlibris.backend.groups

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class GroupSettingsRoutesTest {
    @Test
    fun `update-settings changes name, description, open, searchable and picture, read back from by-id`() =
        authTest {
            val admin: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)
            val name: String = uniqueGroupName("Cercle de lecture")
            val picture: String = client.groupPicture(admin)

            val rename: HttpResponse = client.updateGroup(admin, groupId, "name", "\"$name\"")
            val describe: HttpResponse = client.updateGroup(admin, groupId, "description", "\"Le jeudi soir\"")
            client.updateGroup(admin, groupId, "open", "true")
            client.updateGroup(admin, groupId, "searchable", "false")
            client.updateGroup(admin, groupId, "picture", "\"$picture\"")

            assertEquals(HttpStatusCode.OK, rename.status, rename.bodyAsText())
            assertMatchesFixture("groups/update-settings.name.derived.json", rename.bodyAsText())
            assertEquals(
                GroupSlug.of(name),
                rename
                    .json()
                    .getValue("update")
                    .jsonObject
                    .string("slug"),
            )
            assertMatchesFixture("groups/update-settings.derived.json", describe.bodyAsText())
            val group: JsonObject = client.groupById(groupId)
            assertEquals(name, group.string("name"))
            assertEquals(GroupSlug.of(name), group.string("slug"))
            assertEquals("Le jeudi soir", group.string("description"))
            assertEquals("true", group.string("open"))
            assertEquals("false", group.string("searchable"))
            assertEquals(picture, group.string("picture"))
            assertEquals("6", group.string("_rev").substringBefore('-'))
        }

    @Test
    fun `a picture replaced or taken away is released`() =
        authTest {
            val admin: Reader = client.newReader()
            val groupId: String = client.newGroup(admin)
            val first: String = client.groupPicture(admin)
            val second: String = client.groupPicture(admin)
            client.updateGroup(admin, groupId, "picture", "\"$first\"")

            client.updateGroup(admin, groupId, "picture", "\"$second\"")
            val removed: HttpResponse = client.updateGroup(admin, groupId, "picture", "null")

            assertEquals(HttpStatusCode.OK, removed.status, removed.bodyAsText())
            assertEquals(HttpStatusCode.NotFound, client.getAs(first, null).status)
            assertEquals(HttpStatusCode.NotFound, client.getAs(second, null).status)
            assertFalse("picture" in client.groupById(groupId))
        }

    @Test
    fun `settings refusals keep inventaire's words`() =
        authTest {
            val admin: Reader = client.newReader()
            val member: Reader = client.newReader()
            val groupId: String = client.newGroup(admin, open = true)
            client.groupAction(member, "request", groupId)

            val notAdmin: HttpResponse = client.updateGroup(member, groupId, "name", "\"Pirates\"")
            val attribute: HttpResponse = client.updateGroup(admin, groupId, "creator", "\"${member.id}\"")
            val name: HttpResponse = client.updateGroup(admin, groupId, "name", "\"2024\"")
            val picture: HttpResponse =
                client.updateGroup(admin, groupId, "picture", "\"/img/users/3af17a8d008b00047d93b00b3f77fbe00df75877\"")
            val flag: HttpResponse = client.updateGroup(admin, groupId, "open", "\"true\"")
            val missing: HttpResponse =
                client.putJson(admin, "/api/groups/update-settings", """{"group":"$groupId","attribute":"open"}""")

            assertEquals(HttpStatusCode.Forbidden, notAdmin.status)
            assertMatchesFixture("groups/not-admin.derived.json", notAdmin.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, attribute.status)
            assertMatchesFixture("groups/update-settings.invalid-attribute.derived.json", attribute.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, name.status)
            assertMatchesFixture("groups/update-settings.invalid-name.derived.json", name.bodyAsText())
            assertEquals("invalid_picture", picture.errorName())
            assertEquals("invalid_open", flag.errorName())
            assertEquals("missing_value", missing.errorName())
        }
}
