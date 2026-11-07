package studio.lunabee.exlibris.backend.search

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
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
import studio.lunabee.exlibris.backend.groups.groupPicture
import studio.lunabee.exlibris.backend.groups.newGroup
import studio.lunabee.exlibris.backend.groups.uniqueGroupName
import studio.lunabee.exlibris.backend.groups.updateGroup
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GroupSearchRoutesTest {
    @Test
    fun `a searchable group is found by its name, in inventaire's shape, signed out`() =
        authTest {
            val admin: Reader = client.newReader()
            val name: String = uniqueGroupName("Livres")
            val groupId: String = client.newGroup(admin, name)
            client.updateGroup(admin, groupId, "description", "\"Échanges de livres\"")
            client.updateGroup(admin, groupId, "picture", "\"${client.groupPicture(admin)}\"")

            val response: HttpResponse =
                client.getAs(
                    "/api/search?types=groups&search=${name.substringAfter(' ')}&limit=10",
                    null,
                )

            assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
            assertMatchesFixture("search/groups.json", response.bodyAsText())
            val hit: JsonObject =
                response
                    .json()
                    .getValue("results")
                    .jsonArray
                    .first()
                    .jsonObject
            assertEquals(groupId, hit.getValue("id").jsonPrimitive.content)
            assertEquals(name, hit.getValue("label").jsonPrimitive.content)
            val expected: JsonArray = fixture("search/groups.json").getValue("results").jsonArray
            assertMatchesShape(expected[0].jsonObject, hit, "a group with a description and a picture")
        }

    @Test
    fun `a group that is not searchable is never found`() =
        authTest {
            val admin: Reader = client.newReader()
            val name: String = uniqueGroupName("Secret")
            val hidden: String = client.newGroup(admin, name, searchable = false)
            val shown: String = client.newGroup(admin, "$name bis")
            client.updateGroup(admin, shown, "searchable", "false")
            client.updateGroup(admin, shown, "searchable", "true")

            val ids: List<String> =
                client
                    .getAs("/api/search?types=groups&search=${name.substringAfter(' ')}", null)
                    .json()
                    .getValue("results")
                    .jsonArray
                    .map {
                        it.jsonObject
                            .getValue("id")
                            .jsonPrimitive.content
                    }

            assertEquals(listOf(shown), ids)
            assertTrue(hidden !in ids)
        }
}
