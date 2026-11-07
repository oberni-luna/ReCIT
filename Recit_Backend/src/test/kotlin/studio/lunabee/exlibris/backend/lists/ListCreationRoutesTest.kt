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
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.postJsonAnonymously
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ListCreationRoutesTest {
    @Test
    fun `a list created answers it as inventaire does, and by-creators returns it without elements`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse =
                    client.postList(reader, """{"name":"Polars","description":"","visibility":[],"type":"work"}""")

                assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
                assertMatchesFixture("lists/create.derived.json", response.bodyAsText())
                val list: JsonObject = response.json().getValue("list").jsonObject
                assertMatchesShape(fixture("lists/create.derived.json").getValue("list").jsonObject, list, "the list")
                assertTrue(Regex("^[0-9a-f]{32}$").matches(list.id()))
                val synced: JsonObject = client.listsOf(listOf(reader.id), reader).single()
                assertEquals(list.id(), synced.id())
                assertMatchesShape(
                    fixture("lists/by-creators.empty-list.json").objects("lists").first(),
                    synced,
                    "the list synced",
                )
                assertEquals(emptyList(), synced.elements())
            }
        }

    @Test
    fun `a list without a type is a list of works, the legacy action creates one too`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val legacy: HttpResponse =
                    client.postJson(
                        "/api/lists?action=create",
                        """{"name":"Sans type"}""",
                        reader.cookies,
                    )
                val authors: HttpResponse = client.postList(reader, """{"name":"Autrices","type":"author"}""")

                assertEquals(HttpStatusCode.Created, legacy.status, legacy.bodyAsText())
                assertEquals(
                    "work",
                    legacy
                        .json()
                        .list()
                        .getValue("type")
                        .jsonPrimitive.content,
                )
                assertEquals(
                    "",
                    legacy
                        .json()
                        .list()
                        .getValue("description")
                        .jsonPrimitive.content,
                )
                assertEquals(
                    "author",
                    authors
                        .json()
                        .list()
                        .getValue("type")
                        .jsonPrimitive.content,
                )
            }
        }

    @Test
    fun `an unknown type, a missing name and an anonymous call are refused as inventaire refuses them`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val wrongType: HttpResponse = client.postList(reader, """{"name":"Étagère","type":"shelf"}""")
                val noName: HttpResponse = client.postList(reader, """{"description":"x"}""")
                val anonymous: HttpResponse = client.postJsonAnonymously("/api/lists", """{"name":"Polars"}""")

                assertEquals(HttpStatusCode.BadRequest, wrongType.status)
                assertMatchesFixture("lists/create.invalid-type.derived.json", wrongType.bodyAsText())
                assertEquals(HttpStatusCode.BadRequest, noName.status)
                assertEquals(
                    "missing_name",
                    noName
                        .json()
                        .getValue("error_name")
                        .jsonPrimitive.content,
                )
                assertEquals(HttpStatusCode.Unauthorized, anonymous.status)
                assertMatchesFixture("lists/create.anonymous.derived.json", anonymous.bodyAsText())
            }
        }

    private fun JsonObject.list(): JsonObject = getValue("list").jsonObject
}
