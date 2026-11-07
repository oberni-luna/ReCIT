package studio.lunabee.exlibris.backend.lists

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.strings
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ListUpdateRoutesTest {
    @Test
    fun `an update changes name, description and visibility, as the apps send all three`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)

                val response: HttpResponse =
                    client.putJson(
                        reader,
                        "/api/lists",
                        """{"id":"$listId","name":"Romans noirs","description":"Les sombres",""" +
                            """"visibility":["friends"]}""",
                    )

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("lists/update.derived.json", response.bodyAsText())
                val list: JsonObject = response.json().getValue("list").jsonObject
                assertMatchesShape(fixture("lists/update.derived.json").getValue("list").jsonObject, list, "the list")
                assertEquals("Romans noirs", list.getValue("name").jsonPrimitive.content)
                assertEquals("Les sombres", list.getValue("description").jsonPrimitive.content)
                assertEquals(listOf("friends"), list.strings("visibility"))
                assertTrue(
                    list
                        .getValue("_rev")
                        .jsonPrimitive.content
                        .startsWith("2-"),
                )
                val synced: JsonObject = client.listsOf(listOf(reader.id), reader).single()
                assertEquals("Romans noirs", synced.getValue("name").jsonPrimitive.content)
                assertEquals(listOf("friends"), synced.strings("visibility"))
            }
        }

    @Test
    fun `changing nothing is refused, and so is someone else's list`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val listId: String = client.newList(owner)

                val unchanged: HttpResponse =
                    client.putJson(owner, "/api/lists", """{"id":"$listId","name":"Polars","description":""}""")
                val foreign: HttpResponse = client.putJson(other, "/api/lists", """{"id":"$listId","name":"À moi"}""")

                assertEquals(HttpStatusCode.BadRequest, unchanged.status)
                assertMatchesFixture("lists/update.nothing-to-update.derived.json", unchanged.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, foreign.status)
                assertMatchesFixture("lists/wrong-user.derived.json", foreign.bodyAsText())
            }
        }
}
