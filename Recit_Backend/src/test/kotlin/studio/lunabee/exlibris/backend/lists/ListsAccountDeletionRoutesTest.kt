package studio.lunabee.exlibris.backend.lists

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.deleteAs
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class ListsAccountDeletionRoutesTest {
    @Test
    fun `deleting an account removes its lists and their elements`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                client.newElements(reader, listId, WORK_1984)

                assertEquals(HttpStatusCode.OK, client.deleteAs("/api/user", reader).status)

                assertEquals(
                    0,
                    AuthTestEnvironment.queryLong("SELECT count(*) FROM lists WHERE creator = '${reader.id}'"),
                )
                assertEquals(
                    0,
                    AuthTestEnvironment.queryLong("SELECT count(*) FROM list_elements WHERE list_id = '$listId'"),
                )
            }
        }
}
