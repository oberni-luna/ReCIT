package studio.lunabee.exlibris.backend.items

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.deleteAs
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class ItemsAccountDeletionRoutesTest {
    @Test
    fun `deleting an account removes its books and étagères, and their filing`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val shelfId: String = client.newShelf(reader)
                val itemId: String = client.newBook(reader).id()
                client.shelfAction(reader, "add-items", """{"id":"$shelfId","items":["$itemId"]}""")

                assertEquals(HttpStatusCode.OK, client.deleteAs("/api/user", reader).status)

                assertEquals(0, count("SELECT count(*) FROM items WHERE owner = '${reader.id}'"))
                assertEquals(0, count("SELECT count(*) FROM shelves WHERE owner = '${reader.id}'"))
                assertEquals(0, count("SELECT count(*) FROM item_shelves WHERE item_id = '$itemId'"))
            }
        }

    private fun count(query: String): Long = AuthTestEnvironment.queryLong(query)
}
