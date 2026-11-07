package studio.lunabee.exlibris.backend.shelves

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
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.newShelf
import studio.lunabee.exlibris.backend.items.shelfAction
import studio.lunabee.exlibris.backend.items.strings
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ShelvesRoutesTest {
    @Test
    fun `an étagère created answers it as inventaire does, 201 and its visibility for the owner`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val response: HttpResponse =
                    client.shelfAction(
                        reader,
                        "create",
                        """{"name":"Lus","visibility":["friends"]}""",
                    )

                assertEquals(HttpStatusCode.Created, response.status)
                assertMatchesFixture("shelves/create.derived.json", response.bodyAsText())
                val shelf: JsonObject = response.json().getValue("shelf").jsonObject
                assertMatchesShape(
                    fixture("shelves/create.derived.json").getValue("shelf").jsonObject,
                    shelf,
                    "the étagère",
                )
                assertEquals(listOf("friends"), shelf.strings("visibility"))
                assertTrue(Regex("^[0-9a-f]{32}$").matches(shelf.id()))
            }
        }

    @Test
    fun `an update by the legacy shelf key answers the étagère changed, nothing changed is refused`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader, visibility = """["friends"]""")

                val renamed: HttpResponse =
                    client.shelfAction(reader, "update", """{"shelf":"$shelfId","name":"Déjà lus","color":"#114b01"}""")
                val unchanged: HttpResponse =
                    client.putJson(
                        reader,
                        "/api/shelves",
                        """{"id":"$shelfId","name":"Déjà lus"}""",
                    )

                assertEquals(HttpStatusCode.OK, renamed.status, renamed.bodyAsText())
                assertMatchesFixture("shelves/update.derived.json", renamed.bodyAsText())
                val shelf: JsonObject = renamed.json().getValue("shelf").jsonObject
                assertMatchesShape(
                    fixture("shelves/update.derived.json").getValue("shelf").jsonObject,
                    shelf,
                    "the étagère",
                )
                assertEquals("Déjà lus", shelf.getValue("name").jsonPrimitive.content)
                assertTrue(
                    shelf
                        .getValue("_rev")
                        .jsonPrimitive.content
                        .startsWith("2-"),
                )
                assertEquals(HttpStatusCode.BadRequest, unchanged.status)
                assertMatchesFixture("shelves/update.nothing-to-update.derived.json", unchanged.bodyAsText())
            }
        }

    @Test
    fun `someone else's étagère is refused to update and delete`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val shelfId: String = client.newShelf(owner)

                val update: HttpResponse = client.shelfAction(other, "update", """{"id":"$shelfId","name":"À moi"}""")
                val delete: HttpResponse = client.shelfAction(other, "delete", """{"ids":["$shelfId"]}""")

                assertEquals(HttpStatusCode.Forbidden, update.status)
                assertMatchesFixture("shelves/wrong-owner.derived.json", update.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, delete.status)
                assertMatchesFixture("shelves/wrong-owner.derived.json", delete.bodyAsText())
            }
        }

    @Test
    fun `a friend sees my friends étagère through by-owners without its visibility, a stranger does not`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                client.befriend(owner, friend)
                val shared: String = client.newShelf(owner, "Partagée", """["friends"]""")
                val private: String = client.newShelf(owner, "Secrète")

                val asOwner: HttpResponse = client.getAs("/api/shelves?action=by-owners&owners=${owner.id}", owner)
                val asFriend: JsonObject = shelvesOf(client.getAs("/api/shelves/by-owners?owners=${owner.id}", friend))
                val asStranger: JsonObject =
                    shelvesOf(client.getAs("/api/shelves/by-owners?owners=${owner.id}", stranger))

                assertEquals(setOf(shared, private), shelvesOf(asOwner).keys)
                assertMatchesShape(
                    fixture(
                        "shelves/by-owners.owner.derived.json",
                    ).getValue("shelves").jsonObject.values.single().jsonObject,
                    shelvesOf(asOwner).getValue(private).jsonObject,
                    "my étagère",
                )
                assertEquals(setOf(shared), asFriend.keys)
                assertTrue("visibility" !in asFriend.getValue(shared).jsonObject)
                assertTrue(asStranger.isEmpty())
            }
        }

    @Test
    fun `a public étagère reads signed out as inventaire's, with the ids of the books on it`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val shelfId: String = client.newShelf(owner, visibility = """["public"]""")
                client.shelfAction(owner, "update", """{"id":"$shelfId","color":"#30d303"}""")

                val byOwners: HttpResponse = client.getAs("/api/shelves/by-owners?owners=${owner.id}", null)
                val byIds: HttpResponse = client.getAs("/api/shelves?action=by-ids&ids=$shelfId&with-items=true", null)

                assertMatchesFixture("shelves/by-owners.json", byOwners.bodyAsText())
                assertMatchesShape(
                    fixture("shelves/by-owners.json")
                        .getValue("shelves")
                        .jsonObject.values
                        .first()
                        .jsonObject,
                    shelvesOf(byOwners).getValue(shelfId).jsonObject,
                    "a public étagère",
                )
                assertMatchesShape(
                    fixture("shelves/by-ids.with-items.json")
                        .getValue("shelves")
                        .jsonObject.values
                        .first()
                        .jsonObject,
                    shelvesOf(byIds).getValue(shelfId).jsonObject,
                    "a public étagère with its books",
                )
            }
        }

    @Test
    fun `by-ids answers 404 for an unknown étagère, 401 signed out and 403 signed in for one hidden`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                val shelfId: String = client.newShelf(owner)

                val unknown: HttpResponse =
                    client.getAs(
                        "/api/shelves/by-ids?ids=0123456789abcdef0123456789abcdef",
                        null,
                    )
                val anonymous: HttpResponse = client.getAs("/api/shelves/by-ids?ids=$shelfId", null)
                val forbidden: HttpResponse = client.getAs("/api/shelves/by-ids?ids=$shelfId", stranger)

                assertEquals(HttpStatusCode.NotFound, unknown.status)
                assertMatchesFixture("shelves/by-ids.not-found.json", unknown.bodyAsText())
                assertEquals(HttpStatusCode.Unauthorized, anonymous.status)
                assertMatchesFixture("shelves/by-ids.anonymous.derived.json", anonymous.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, forbidden.status)
                assertMatchesFixture("shelves/by-ids.forbidden.derived.json", forbidden.bodyAsText())
            }
        }

    private suspend fun shelvesOf(response: HttpResponse): JsonObject = response.json().getValue("shelves").jsonObject
}
