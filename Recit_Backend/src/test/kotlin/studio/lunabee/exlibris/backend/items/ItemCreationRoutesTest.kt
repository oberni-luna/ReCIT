package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.entities.InventaireStub
import studio.lunabee.exlibris.backend.entities.exLibrisUserAgent
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.groups.newGroup
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ItemCreationRoutesTest {
    @Test
    fun `a book created from an isbn answers its item, with inventaire's title and a 32-hex id`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse =
                    client.postItem(
                        reader,
                        """{"entity":"$ISBN_1984","transaction":"inventorying","visibility":[],"shelves":[]}""",
                    )

                assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
                assertMatchesFixture("items/create.derived.json", response.bodyAsText())
                val item: JsonObject = response.json().getValue("item").jsonObject
                assertMatchesShape(fixture("items/create.derived.json").getValue("item").jsonObject, item, "the item")
                assertTrue(Regex("^[0-9a-f]{32}$").matches(item.id()))
                assertEquals(EDITION_1984, item.getValue("entity").jsonPrimitive.content)
                assertEquals(reader.id, item.getValue("owner").jsonPrimitive.content)
                val snapshot: JsonObject = item.getValue("snapshot").jsonObject
                assertMatchesShape(
                    fixture("items/create.derived.json")
                        .getValue("item")
                        .jsonObject
                        .getValue("snapshot")
                        .jsonObject,
                    snapshot,
                    "the snapshot",
                )
                assertEquals("1984", snapshot.getValue("entity:title").jsonPrimitive.content)
                assertEquals(
                    "George Orwell, Amélie Audiberti",
                    snapshot.getValue("entity:authors").jsonPrimitive.content,
                )
                assertEquals(listOf(WORK_1984), snapshot.strings("entity:worksUris"))
                assertTrue(
                    stub.requests
                        .single()
                        .uri
                        .startsWith("/api/entities/by-uris?uris=$ISBN_1984"),
                )
                assertTrue(
                    exLibrisUserAgent.matches(
                        stub.requests
                            .single()
                            .header(HttpHeaders.UserAgent)
                            .orEmpty(),
                    ),
                )
            }
        }

    @Test
    fun `an edition inventaire does not know answers 400, and no book is stored`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse = client.postItem(reader, """{"entity":"$UNKNOWN_EDITION"}""")

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertMatchesFixture("items/create.unknown-entity.derived.json", response.bodyAsText())
                assertEquals(0, booksOf(reader))
            }
        }

    @Test
    fun `an invalid uri is refused before inventaire is asked`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse = client.postItem(reader, """{"entity":"isbn:12"}""")

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertMatchesFixture("items/create.invalid-entity.derived.json", response.bodyAsText())
                assertTrue(stub.requests.isEmpty())
            }
        }

    @Test
    fun `inventaire unreachable fails the creation rather than storing a book without a title`() =
        relayTest(InventaireStub().also { it.close() }) {
            val reader: Reader = client.newReader()

            val response: HttpResponse = client.postItem(reader, """{"entity":"$ISBN_1984"}""")

            assertEquals(HttpStatusCode.BadGateway, response.status)
            assertEquals(0, booksOf(reader))
        }

    @Test
    fun `a group key naming a group the owner is not in is refused, one they are in accepted`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val other: Reader = client.newReader()
                val theirs: String = client.newGroup(other)
                val mine: String = client.newGroup(reader)

                val refused: HttpResponse =
                    client.postItem(reader, """{"entity":"$ISBN_1984","visibility":["group:$theirs"]}""")
                val accepted: HttpResponse =
                    client.postItem(reader, """{"entity":"$ISBN_1984","visibility":["group:$mine","friends"]}""")

                assertEquals(HttpStatusCode.BadRequest, refused.status)
                assertMatchesFixture("items/visibility.not-in-group.derived.json", refused.bodyAsText())
                assertEquals(HttpStatusCode.Created, accepted.status)
                assertEquals(
                    listOf("group:$mine", "friends"),
                    accepted
                        .json()
                        .getValue("item")
                        .jsonObject
                        .strings("visibility"),
                )
            }
        }

    @Test
    fun `a book is created only with a session`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val response: HttpResponse = client.postJsonAnonymously("/api/items", """{"entity":"$ISBN_1984"}""")

                assertEquals(HttpStatusCode.Unauthorized, response.status)
                assertMatchesFixture("relations/relations.anonymous.json", response.bodyAsText())
            }
        }

    private fun booksOf(reader: Reader): Long =
        AuthTestEnvironment.queryLong("SELECT count(*) FROM items WHERE owner = '${reader.id}'")
}
