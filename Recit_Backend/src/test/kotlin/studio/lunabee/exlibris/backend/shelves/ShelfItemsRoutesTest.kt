package studio.lunabee.exlibris.backend.shelves

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.newBook
import studio.lunabee.exlibris.backend.items.newShelf
import studio.lunabee.exlibris.backend.items.shelfAction
import studio.lunabee.exlibris.backend.items.strings
import studio.lunabee.exlibris.backend.items.visibleItems
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ShelfItemsRoutesTest {
    @Test
    fun `a book filed answers the étagère with its books, and the book names the étagère`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader, visibility = """["friends"]""")
                val itemId: String = client.newBook(reader).id()

                val response: HttpResponse =
                    client.shelfAction(
                        reader,
                        "add-items",
                        """{"id":"$shelfId","items":["$itemId"]}""",
                    )

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("shelves/add-items.derived.json", response.bodyAsText())
                val shelf: JsonObject =
                    response
                        .json()
                        .getValue("shelves")
                        .jsonObject
                        .getValue(shelfId)
                        .jsonObject
                assertMatchesShape(
                    fixture("shelves/add-items.derived.json")
                        .getValue("shelves")
                        .jsonObject.values
                        .single()
                        .jsonObject,
                    shelf,
                    "the étagère",
                )
                assertEquals(listOf(itemId), shelf.strings("items"))
                val item: JsonObject = client.visibleItems(listOf(itemId), reader).single()
                assertEquals(listOf(shelfId), item.strings("shelves"))
                assertTrue(item.getValue("_rev").toString().contains("2-"))
            }
        }

    @Test
    fun `a book taken off answers the étagère emptied, by POST and by PUT`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader)
                val itemId: String = client.newBook(reader).id()
                client.putJson(reader, "/api/shelves/add-items", """{"id":"$shelfId","items":["$itemId"]}""")

                val response: HttpResponse =
                    client.shelfAction(reader, "remove-items", """{"id":"$shelfId","items":["$itemId"]}""")

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("shelves/add-items.derived.json", response.bodyAsText())
                assertTrue(
                    response
                        .json()
                        .getValue(
                            "shelves",
                        ).jsonObject
                        .getValue(shelfId)
                        .jsonObject
                        .strings("items")
                        .isEmpty(),
                )
                assertTrue(
                    client
                        .visibleItems(listOf(itemId), reader)
                        .single()
                        .strings("shelves")
                        .isEmpty(),
                )
            }
        }

    @Test
    fun `someone else's book cannot be filed, nor a book on someone else's étagère`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val mine: String = client.newShelf(owner)
                val theirs: String = client.newShelf(other)
                val theirBook: String = client.newBook(other).id()
                val myBook: String = client.newBook(owner).id()

                val book: HttpResponse =
                    client.shelfAction(
                        owner,
                        "add-items",
                        """{"id":"$mine","items":["$theirBook"]}""",
                    )
                val shelf: HttpResponse =
                    client.shelfAction(
                        owner,
                        "add-items",
                        """{"id":"$theirs","items":["$myBook"]}""",
                    )

                assertEquals(HttpStatusCode.BadRequest, book.status)
                assertMatchesFixture("shelves/add-items.item-not-owned.derived.json", book.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, shelf.status)
                assertMatchesFixture("shelves/wrong-owner.derived.json", shelf.bodyAsText())
            }
        }
}
