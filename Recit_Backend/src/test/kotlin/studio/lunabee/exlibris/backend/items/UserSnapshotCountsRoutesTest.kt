package studio.lunabee.exlibris.backend.items

import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class UserSnapshotCountsRoutesTest {
    @Test
    fun `a book created counts one more in its visibility's section, its creation the last add`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val before: JsonObject = snapshotOf(owner, owner)

                val forFriends: JsonObject = client.newBook(owner, """["friends"]""")
                val public: JsonObject = client.newBook(owner, """["public"]""")
                client.newBook(owner)

                val mine: JsonObject = snapshotOf(owner, owner)
                assertEquals(0, before.count("network"))
                assertNull(before.lastAdd("network"))
                assertEquals(1, mine.count("private"))
                assertEquals(1, mine.count("network"))
                assertEquals(1, mine.count("public"))
                assertEquals(created(forFriends), mine.lastAdd("network"))
                assertEquals(created(public), mine.lastAdd("public"))
                assertEquals(
                    1,
                    client
                        .getAs("/api/user", owner)
                        .json()
                        .getValue("snapshot")
                        .jsonObject
                        .count("public"),
                )
            }
        }

    @Test
    fun `a friend reads the network and public sections, anyone else the public one`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                client.newBook(owner, """["friends"]""")

                val asFriend: JsonObject = snapshotOf(owner, friend)

                assertEquals(setOf("network", "public"), asFriend.keys)
                assertEquals(1, asFriend.count("network"))
                assertEquals(setOf("public"), snapshotOf(owner, null).keys)
            }
        }

    private suspend fun ApplicationTestBuilder.snapshotOf(
        owner: Reader,
        viewer: Reader?,
    ): JsonObject =
        client
            .getAs("/api/users?action=by-ids&ids=${owner.id}", viewer)
            .json()
            .getValue("users")
            .jsonObject
            .getValue(owner.id)
            .jsonObject
            .getValue("snapshot")
            .jsonObject

    private fun JsonObject.count(section: String): Int =
        getValue(section)
            .jsonObject
            .getValue("items:count")
            .jsonPrimitive.int

    private fun JsonObject.lastAdd(section: String): Long? =
        getValue(section).jsonObject["items:last-add"]?.jsonPrimitive?.long

    private fun created(item: JsonObject): Long = item.getValue("created").jsonPrimitive.long
}
