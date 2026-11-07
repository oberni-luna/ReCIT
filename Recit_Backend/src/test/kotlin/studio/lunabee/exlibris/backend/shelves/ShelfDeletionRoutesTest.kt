package studio.lunabee.exlibris.backend.shelves

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
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

class ShelfDeletionRoutesTest {
    @Test
    fun `an étagère deleted keeps its books in the inventory, off it`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader, visibility = """["friends"]""")
                val itemId: String = client.newBook(reader).id()
                client.shelfAction(reader, "add-items", """{"id":"$shelfId","items":["$itemId"]}""")

                val response: HttpResponse = client.shelfAction(reader, "delete", """{"ids":["$shelfId"]}""")

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("shelves/delete.derived.json", response.bodyAsText())
                val echoed: JsonObject =
                    response
                        .json()
                        .getValue("shelves")
                        .jsonArray
                        .single()
                        .jsonObject
                assertMatchesShape(
                    fixture("shelves/delete.derived.json")
                        .getValue("shelves")
                        .jsonArray
                        .single()
                        .jsonObject,
                    echoed,
                    "the étagère deleted",
                )
                assertEquals(listOf(itemId), echoed.strings("items"))
                val item: JsonObject = client.visibleItems(listOf(itemId), reader).single()
                assertTrue(item.strings("shelves").isEmpty())
            }
        }

    @Test
    fun `an étagère deleted with-items deletes its books with it`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader, visibility = """["friends"]""")
                val filed: String = client.newBook(reader).id()
                val loose: String = client.newBook(reader).id()
                client.shelfAction(reader, "add-items", """{"id":"$shelfId","items":["$filed"]}""")

                val response: HttpResponse =
                    client.shelfAction(reader, "delete", """{"ids":["$shelfId"],"with-items":true}""")

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("shelves/delete.with-items.derived.json", response.bodyAsText())
                assertMatchesShape(
                    fixture("shelves/delete.with-items.derived.json")
                        .getValue("items")
                        .jsonArray
                        .single()
                        .jsonObject,
                    response
                        .json()
                        .getValue("items")
                        .jsonArray
                        .single()
                        .jsonObject,
                    "the book deleted",
                )
                assertTrue(client.visibleItems(listOf(filed), reader).isEmpty())
                assertEquals(listOf(loose), client.visibleItems(listOf(filed, loose), reader).map { it.id() })
            }
        }
}
