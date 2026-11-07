package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.entities.StubAnswer
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class BulkUpdateRoutesTest {
    @Test
    fun `notes written answer ok, and are shown to the owner and not to a friend`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val itemId: String = client.newBook(owner, """["friends"]""").id()

                val response: HttpResponse =
                    client.bulkUpdate(owner, """{"ids":["$itemId"],"attribute":"notes","value":"x"}""")

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
                val mine: JsonObject = client.visibleItems(listOf(itemId), owner).single()
                assertEquals("x", mine.getValue("notes").jsonPrimitive.content)
                assertTrue(
                    mine
                        .getValue("_rev")
                        .jsonPrimitive.content
                        .startsWith("2-"),
                )
                assertTrue("notes" !in client.visibleItems(listOf(itemId), friend).single())
            }
        }

    @Test
    fun `every attribute inventaire accepts is written, the legacy and current paths alike`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val shelfId: String = client.newShelf(owner)
                val itemId: String = client.newBook(owner).id()
                val ids = """["$itemId"]"""

                client.bulkUpdate(owner, """{"ids":$ids,"attribute":"transaction","value":"lending"}""")
                client.bulkUpdate(owner, """{"ids":$ids,"attribute":"details","value":"Un classique"}""")
                client.bulkUpdate(owner, """{"ids":$ids,"attribute":"visibility","value":["public"]}""")
                client.putJson(owner, "/api/items/bulk", """{"ids":$ids,"attribute":"shelves","value":["$shelfId"]}""")
                val entity: HttpResponse =
                    client.putJson(
                        owner,
                        "/api/items?action=bulk-update",
                        """{"ids":$ids,"attribute":"entity","value":"$EDITION_1984"}""",
                    )

                assertEquals(HttpStatusCode.OK, entity.status, entity.bodyAsText())
                val item: JsonObject = client.visibleItems(listOf(itemId), null).single()
                assertEquals("lending", item.getValue("transaction").jsonPrimitive.content)
                assertEquals("Un classique", item.getValue("details").jsonPrimitive.content)
                assertEquals(listOf(shelfId), client.visibleItems(listOf(itemId), owner).single().strings("shelves"))
            }
        }

    @Test
    fun `someone else's book, an unknown attribute and an invalid value are refused as inventaire refuses them`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val itemId: String = client.newBook(owner).id()

                val notOwner: HttpResponse =
                    client.bulkUpdate(other, """{"ids":["$itemId"],"attribute":"notes","value":"x"}""")
                val attribute: HttpResponse =
                    client.bulkUpdate(owner, """{"ids":["$itemId"],"attribute":"color","value":"#ffffff"}""")
                val value: HttpResponse =
                    client.bulkUpdate(owner, """{"ids":["$itemId"],"attribute":"transaction","value":"renting"}""")

                assertEquals(HttpStatusCode.BadRequest, notOwner.status)
                assertMatchesFixture("items/bulk-update.not-owner.derived.json", notOwner.bodyAsText())
                assertEquals(HttpStatusCode.BadRequest, attribute.status)
                assertMatchesFixture("items/bulk-update.invalid-attribute.derived.json", attribute.bodyAsText())
                assertEquals(HttpStatusCode.BadRequest, value.status)
                assertEquals(
                    "invalid_transaction",
                    value
                        .json()
                        .getValue("error_name")
                        .jsonPrimitive.content,
                )
            }
        }

    @Test
    fun `a bulk-update reads the edition again when its snapshot was read a while ago`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val itemId: String = client.newBook(owner).id()
                AuthTestEnvironment.execute("UPDATE entity_snapshots SET refreshed = 0 WHERE uri = '$EDITION_1984'")
                stub.answer = { StubAnswer.json(retitled("Mil neuf cent quatre-vingt-quatre")) }

                client.bulkUpdate(owner, """{"ids":["$itemId"],"attribute":"notes","value":"relu"}""")

                val snapshot: JsonObject =
                    client
                        .visibleItems(
                            listOf(itemId),
                            owner,
                        ).single()
                        .getValue("snapshot")
                        .jsonObject
                assertEquals(
                    "Mil neuf cent quatre-vingt-quatre",
                    snapshot.getValue("entity:title").jsonPrimitive.content,
                )
                assertEquals(2, stub.requests.size)
            }
        }

    @Test
    fun `a bulk-update right after the creation does not ask inventaire again`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val itemId: String = client.newBook(owner).id()

                client.bulkUpdate(owner, """{"ids":["$itemId"],"attribute":"notes","value":"a"}""")

                assertEquals(1, stub.requests.size)
            }
        }
}

/** The captured « 1984 » answer with another edition title, as inventaire.io would answer once it was corrected. */
fun retitled(title: String): String =
    FixtureAssertions
        .read("entities/by-uris.isbn-9782070368228.relatives.json")
        .replace(""""wdt:P1476":["1984"]""", """"wdt:P1476":["$title"]""")
