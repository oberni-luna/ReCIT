package studio.lunabee.exlibris.backend.items

import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonObject
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.groups.groupAction
import studio.lunabee.exlibris.backend.groups.newGroup
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ItemsVisibilityRoutesTest {
    @Test
    fun `a friend sees a friends book in by-ids and inventory-view, a stranger and an anonymous session do not`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                client.befriend(owner, friend)
                val itemId: String = client.newBook(owner, """["friends"]""").id()

                assertEquals(listOf(itemId), client.visibleItems(listOf(itemId), friend).map { it.id() })
                assertTrue(client.visibleItems(listOf(itemId), stranger).isEmpty())
                assertTrue(client.visibleItems(listOf(itemId), null).isEmpty())
                assertEquals(listOf(itemId), viewedItems(owner, friend))
                assertTrue(viewedItems(owner, stranger).isEmpty())
                assertTrue(viewedItems(owner, null).isEmpty())
            }
        }

    @Test
    fun `a member of a group the owner is in sees a groups book, a friend outside every shared group does not`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val member: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val groupId: String = client.newGroup(owner, open = true)
                client.groupAction(member, "request", groupId)
                client.befriend(owner, friend)
                val itemId: String = client.newBook(owner, """["groups"]""").id()

                assertEquals(listOf(itemId), client.visibleItems(listOf(itemId), member).map { it.id() })
                assertEquals(listOf(itemId), viewedItems(owner, member))
                assertTrue(client.visibleItems(listOf(itemId), friend).isEmpty())
                assertTrue(viewedItems(owner, friend).isEmpty())
            }
        }

    @Test
    fun `a group key shows the book to that group's members only, and private attributes to the owner only`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val member: Reader = client.newReader()
                val otherMember: Reader = client.newReader()
                val groupId: String = client.newGroup(owner, open = true)
                val otherGroup: String = client.newGroup(otherMember, open = true)
                client.groupAction(member, "request", groupId)
                client.groupAction(owner, "request", otherGroup)
                val itemId: String = client.newBook(owner, """["group:$groupId"]""").id()

                val seen: JsonObject = client.visibleItems(listOf(itemId), member).single()
                assertTrue(client.visibleItems(listOf(itemId), otherMember).isEmpty())
                assertTrue("visibility" !in seen && "notes" !in seen)
                assertEquals(
                    listOf("group:$groupId"),
                    client.visibleItems(listOf(itemId), owner).single().strings("visibility"),
                )
            }
        }

    private suspend fun ApplicationTestBuilder.viewedItems(
        owner: Reader,
        viewer: Reader?,
    ): List<String> = client.inventoryView("user=${owner.id}", viewer).json().strings("itemsByDate")
}
