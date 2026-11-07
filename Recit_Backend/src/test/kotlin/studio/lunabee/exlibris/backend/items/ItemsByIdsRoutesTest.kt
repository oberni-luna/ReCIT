package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ItemsByIdsRoutesTest {
    @Test
    fun `a public book answers its snapshot, total and offset, as inventaire shows it signed out`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader, visibility = """["public"]""")
                val itemId: String = client.newBook(reader, """["public"]""").id()
                client.shelfAction(reader, "add-items", """{"id":"$shelfId","items":["$itemId"]}""")

                val response: HttpResponse = client.getAs("/api/items/by-ids?ids=$itemId", null)

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("items/by-ids.json", response.bodyAsText())
                val captured: JsonObject = fixture("items/by-ids.json").getValue("items").jsonArray[0].jsonObject
                val item: JsonObject =
                    response
                        .json()
                        .getValue("items")
                        .jsonArray
                        .single()
                        .jsonObject
                assertMatchesShape(captured, item, "a public book")
                assertEquals(listOf(shelfId), item.strings("shelves"))
                assertEquals(
                    false,
                    item
                        .getValue("busy")
                        .jsonPrimitive.content
                        .toBooleanStrict(),
                )
                assertEquals(
                    "1984",
                    item
                        .getValue("snapshot")
                        .jsonObject
                        .getValue("entity:title")
                        .jsonPrimitive.content,
                )
                assertEquals(
                    1,
                    response
                        .json()
                        .getValue("total")
                        .jsonPrimitive.int,
                )
            }
        }

    @Test
    fun `the owner reads every attribute of their book, the étagères included`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val itemId: String = client.newBook(reader, """["friends"]""").id()
                client.bulkUpdate(reader, """{"ids":["$itemId"],"attribute":"notes","value":"x"}""")
                client.bulkUpdate(reader, """{"ids":["$itemId"],"attribute":"details","value":""}""")

                val response: HttpResponse = client.getAs("/api/items/by-ids?ids=$itemId", reader)

                assertMatchesFixture("items/by-ids.owner.derived.json", response.bodyAsText())
                assertMatchesShape(
                    fixture("items/by-ids.owner.derived.json").getValue("items").jsonArray[0].jsonObject,
                    response
                        .json()
                        .getValue("items")
                        .jsonArray
                        .single()
                        .jsonObject,
                    "the owner's book",
                )
            }
        }

    @Test
    fun `an unknown id answers no book, a page cut by limit and offset keeps the total`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val older: String = client.newBook(reader).id()
                val newer: String = client.newBook(reader).id()

                val unknown: HttpResponse = client.getAs("/api/items/by-ids?ids=$UNKNOWN_ID", reader)
                val page: JsonObject =
                    client
                        .getAs(
                            "/api/items/by-ids?ids=$older|$newer&limit=1&offset=1",
                            reader,
                        ).json()
                val legacy: HttpResponse = client.getAs("/api/items?action=by-ids&ids=$older", reader)

                assertMatchesFixture("items/by-ids.unknown.json", unknown.bodyAsText())
                assertTrue(
                    unknown
                        .json()
                        .getValue("items")
                        .jsonArray
                        .isEmpty(),
                )
                assertEquals(2, page.getValue("total").jsonPrimitive.int)
                assertEquals(1, page.getValue("offset").jsonPrimitive.int)
                assertEquals(listOf(older), page.getValue("items").jsonArray.map { it.jsonObject.id() })
                assertEquals(HttpStatusCode.OK, legacy.status)
                assertFalse(
                    legacy
                        .json()
                        .getValue("items")
                        .jsonArray
                        .isEmpty(),
                )
            }
        }

    @Test
    fun `the copies count of the duplicate review stays relayed to inventaire, without a session`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse = client.getAs("/api/items/by-entities?uris=$EDITION_1984&limit=1", reader)

                assertEquals(HttpStatusCode.OK, response.status)
                assertEquals("/api/items/by-entities?uris=$EDITION_1984&limit=1", stub.requests.single().uri)
            }
        }

    private companion object {
        const val UNKNOWN_ID: String = "0123456789abcdef0123456789abcdef"
    }
}
