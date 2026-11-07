package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ItemDeletionRoutesTest {
    @Test
    fun `a deleted book answers ok, and is gone from by-ids and from every étagère`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val read: String = client.newShelf(owner, "Lus")
                val loved: String = client.newShelf(owner, "Aimés")
                val itemId: String = client.newBook(owner).id()
                client.shelfAction(owner, "add-items", """{"id":"$read","items":["$itemId"]}""")
                client.shelfAction(owner, "add-items", """{"id":"$loved","items":["$itemId"]}""")

                val response: HttpResponse = client.deleteItems(owner, listOf(itemId))

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
                assertTrue(client.visibleItems(listOf(itemId), owner).isEmpty())
                val shelves =
                    client
                        .getAs("/api/shelves?action=by-ids&ids=$read|$loved&with-items=true", owner)
                        .json()
                        .getValue("shelves")
                        .jsonObject
                assertEquals(setOf(read, loved), shelves.keys)
                shelves.values.forEach { assertTrue(it.jsonObject.strings("items").isEmpty()) }
            }
        }

    @Test
    fun `someone else's book is refused, an unknown one skipped, and the legacy path served`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val itemId: String = client.newBook(owner).id()

                val refused: HttpResponse = client.deleteItems(other, listOf(itemId))
                val unknown: HttpResponse = client.deleteItems(owner, listOf("0123456789abcdef0123456789abcdef"))
                val legacy: HttpResponse =
                    client.postJson("/api/items?action=delete-by-ids", """{"ids":["$itemId"]}""", owner.cookies)

                assertEquals(HttpStatusCode.Forbidden, refused.status)
                assertMatchesFixture("items/delete.not-owner.derived.json", refused.bodyAsText())
                assertEquals(HttpStatusCode.OK, unknown.status)
                assertEquals(HttpStatusCode.OK, legacy.status)
                assertTrue(client.visibleItems(listOf(itemId), owner).isEmpty())
            }
        }
}
