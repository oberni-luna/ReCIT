package studio.lunabee.exlibris.backend.relations

import io.ktor.client.HttpClient
import io.ktor.client.statement.HttpResponse
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.groupAction
import studio.lunabee.exlibris.backend.groups.newGroup
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.postRelation
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class RelationsNetworkRoutesTest {
    @Test
    fun `a reader who shares a group with me is in my network, after my friends`() =
        authTest {
            val me: Reader = client.newReader()
            val friend: Reader = client.newReader()
            val coMember: Reader = client.newReader()
            val invited: Reader = client.newReader()
            client.postRelation(me, "request", friend)
            client.postRelation(friend, "accept", me)
            val groupId: String = client.newGroup(me, open = true)
            client.groupAction(coMember, "request", groupId)
            client.groupAction(me, "invite", groupId, invited)

            val relations: JsonObject = client.getAs("/api/relations", me).json()

            assertEquals(listOf(friend.id), relations.ids("friends"))
            assertEquals(listOf(friend.id, coMember.id), relations.ids("network"))
            assertEquals(listOf(me.id), client.getAs("/api/relations", coMember).json().ids("network"))
        }

    @Test
    fun `a co-member sees the network part of my snapshot`() =
        authTest {
            val me: Reader = client.newReader()
            val coMember: Reader = client.newReader()
            val stranger: Reader = client.newReader()
            val groupId: String = client.newGroup(me, open = true)
            client.groupAction(coMember, "request", groupId)

            val seenByCoMember: JsonObject = client.snapshotOf(me, coMember)
            val seenByStranger: JsonObject = client.snapshotOf(me, stranger)

            assertTrue("network" in seenByCoMember)
            assertTrue("network" !in seenByStranger)
        }

    private suspend fun HttpClient.snapshotOf(
        reader: Reader,
        viewer: Reader,
    ): JsonObject {
        val response: HttpResponse = getAs("/api/users/by-ids?ids=${reader.id}", viewer)
        assertEquals(HttpStatusCode.OK, response.status)
        return response
            .json()
            .getValue("users")
            .jsonObject
            .getValue(reader.id)
            .jsonObject
            .getValue("snapshot")
            .jsonObject
    }

    private fun JsonObject.ids(list: String): List<String> = getValue(list).jsonArray.map { it.jsonPrimitive.content }
}
