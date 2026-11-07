package studio.lunabee.exlibris.backend.items

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.groupAction
import studio.lunabee.exlibris.backend.groups.newGroup
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class InventoryViewRoutesTest {
    @Test
    fun `a reader's view has inventaire's keys and types, the new book under its work, without asking inventaire`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val itemId: String = client.newBook(reader).id()
                val asked: Int = stub.requests.size

                val response: HttpResponse = client.inventoryView("user=${reader.id}", reader)

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("items/inventory-view.json", response.bodyAsText())
                val view: JsonObject = response.json()
                val tree: JsonObject = view.getValue("worksTree").jsonObject
                assertMatchesShape(
                    fixture("items/inventory-view.json").getValue("worksTree").jsonObject,
                    tree,
                    "worksTree",
                )
                assertEquals(listOf(itemId), view.getValue("workUriItemsMap").jsonObject.strings(WORK_1984))
                assertEquals(listOf(WORK_1984), tree.getValue("author").jsonObject.strings("wd:Q3335"))
                assertEquals(listOf(WORK_1984), tree.getValue("genre").jsonObject.strings("wd:Q944250"))
                assertEquals(listOf(WORK_1984), tree.getValue("subject").jsonObject.strings("wd:Q8458"))
                assertEquals(
                    listOf(itemId),
                    tree
                        .getValue("owner")
                        .jsonObject
                        .getValue(reader.id)
                        .jsonObject
                        .strings(WORK_1984),
                )
                assertEquals(listOf(itemId), view.strings("itemsByDate"))
                assertEquals(1, view.getValue("totalItems").jsonPrimitive.int)
                assertEquals(asked, stub.requests.size)
            }
        }

    @Test
    fun `without a user, a shelf or a group the view is refused as inventaire refuses it`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val response: HttpResponse = client.inventoryView("", null)

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertMatchesFixture("items/inventory-view.missing.json", response.bodyAsText())
            }
        }

    @Test
    fun `an étagère's view, the books on no étagère, and the legacy path`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader)
                val filed: String = client.newBook(reader).id()
                val loose: String = client.newBook(reader).id()
                client.shelfAction(reader, "add-items", """{"id":"$shelfId","items":["$filed"]}""")

                val onShelf: JsonObject = client.inventoryView("shelf=$shelfId", reader).json()
                val withoutShelf: JsonObject =
                    client
                        .inventoryView(
                            "user=${reader.id}&without-shelf=true",
                            reader,
                        ).json()
                val legacy: HttpResponse = client.getAs("/api/items?action=inventory-view&user=${reader.id}", reader)

                assertEquals(listOf(filed), onShelf.strings("itemsByDate"))
                assertEquals(listOf(loose), withoutShelf.strings("itemsByDate"))
                assertEquals(HttpStatusCode.OK, legacy.status)
                assertEquals(
                    2,
                    legacy
                        .json()
                        .getValue("totalItems")
                        .jsonPrimitive.int,
                )
            }
        }

    @Test
    fun `a group's view shows its members' books through the group's keys only`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val admin: Reader = client.newReader()
                val member: Reader = client.newReader()
                val outsider: Reader = client.newReader()
                val groupId: String = client.newGroup(admin, open = true)
                client.groupAction(member, "request", groupId)
                client.befriend(admin, outsider)
                val forGroups: String = client.newBook(admin, """["groups"]""").id()
                val forFriends: String = client.newBook(admin, """["friends"]""").id()
                val public: String = client.newBook(member, """["public"]""").id()

                val asMember: List<String> =
                    client
                        .inventoryView(
                            "group=$groupId",
                            member,
                        ).json()
                        .strings("itemsByDate")
                val asOutsider: List<String> =
                    client.inventoryView("group=$groupId", outsider).json().strings("itemsByDate")

                assertEquals(setOf(forGroups, public), asMember.toSet())
                assertEquals(listOf(public), asOutsider)
                assertTrue(forFriends !in asMember)
            }
        }
}
