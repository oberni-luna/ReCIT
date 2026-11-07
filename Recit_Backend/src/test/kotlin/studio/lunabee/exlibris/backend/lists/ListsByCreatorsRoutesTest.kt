package studio.lunabee.exlibris.backend.lists

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.strings
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ListsByCreatorsRoutesTest {
    @Test
    fun `a friend sees my friends list, a stranger and an anonymous session do not, and a friend writes nothing`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                client.befriend(owner, friend)
                val shared: String = client.newList(owner, "Partagée", """["friends"]""")
                client.newList(owner, "Secrète")
                client.newElements(owner, shared, WORK_1984)

                val asFriend: List<JsonObject> = client.listsOf(listOf(owner.id), friend)
                val update: HttpResponse = client.putJson(friend, "/api/lists", """{"id":"$shared","name":"À moi"}""")
                val add: HttpResponse = client.addElements(friend, shared, SECOND_WORK)
                val delete: HttpResponse = client.postJson("/api/lists/delete", """{"ids":"$shared"}""", friend.cookies)

                assertEquals(listOf(shared), asFriend.map { it.id() })
                assertEquals(listOf("friends"), asFriend.single().strings("visibility"))
                assertEquals(1, asFriend.single().elements().size)
                assertTrue(client.listsOf(listOf(owner.id), stranger).isEmpty())
                assertTrue(client.listsOf(listOf(owner.id), null).isEmpty())
                listOf(update, add, delete).forEach { refused ->
                    assertEquals(HttpStatusCode.Forbidden, refused.status)
                    assertMatchesFixture("lists/wrong-user.derived.json", refused.bodyAsText())
                }
            }
        }

    @Test
    fun `a public list reads signed out as inventaire's, with its elements in ordinal order`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val listId: String = client.newList(owner, visibility = """["public"]""")
                client.newElements(owner, listId, WORK_1984)
                client.newElements(owner, listId, SECOND_WORK)

                val response: HttpResponse =
                    client.getAs("/api/lists/by-creators?users=${owner.id}&with-elements=true", null)

                assertMatchesFixture("lists/by-creators.json", response.bodyAsText())
                val captured: JsonObject = fixture("lists/by-creators.json").objects("lists").first()
                val list: JsonObject = response.json().objects("lists").single()
                assertMatchesShape(captured, list, "a public list")
                assertMatchesShape(captured.elements().first(), list.elements().first(), "its element")
                assertEquals(listOf(WORK_1984, SECOND_WORK), list.elements().map { it.text("uri") })
            }
        }

    @Test
    fun `fifty creators answer every list the viewer may see, the newest first`() =
        listStub().use { stub ->
            relayTest(stub) {
                val viewer: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(viewer, friend)
                val friendList: String = client.newList(friend, "Amie", """["friends"]""")
                val creators: List<String> = List(CREATORS - 1) { seedCreator(viewer.id, isFriend = it % 3 == 0) }
                val expected: List<String> =
                    creators.flatMapIndexed { index, creator ->
                        listOfNotNull("$creator:public", "$creator:friends".takeIf { index % 3 == 0 })
                    }

                val lists: List<JsonObject> =
                    client.listsOf(creators + friend.id, viewer)

                assertEquals(listOf(friendList) + expected.map(::seededId).reversed(), lists.map { it.id() })
            }
        }

    @Test
    fun `limit, offset, context and the total and images attributes page and enrich as inventaire does`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val group = "group:${DocumentId.new()}"
                val oldest: String = client.newList(owner, "Publique", """["public"]""")
                val middle: String = client.newList(owner, "Amis", """["friends"]""")
                val newest: String = client.newList(owner, "Groupes", """["groups"]""")
                client.newElements(owner, oldest, WORK_1984, SECOND_WORK)
                listOf(oldest, middle, newest).forEachIndexed { index, id ->
                    AuthTestEnvironment.execute("UPDATE lists SET created = ${index + 1} WHERE id = '$id'")
                }

                val page: JsonObject =
                    client.getAs("/api/lists/by-creators?users=${owner.id}&limit=1&offset=1", owner).json()
                val inContext: List<JsonObject> = client.listsOf(listOf(owner.id), owner, "context=$group")
                val enriched: List<JsonObject> = client.listsOf(listOf(owner.id), owner, "attributes=total|images")
                val wrongContext: HttpResponse =
                    client.getAs(
                        "/api/lists/by-creators?users=${owner.id}&context=x",
                        owner,
                    )

                assertEquals(listOf(middle), page.objects("lists").map { it.id() })
                assertEquals(
                    3,
                    page
                        .getValue("total")
                        .jsonPrimitive.content
                        .toInt(),
                )
                assertEquals(
                    2,
                    page
                        .getValue("continue")
                        .jsonPrimitive.content
                        .toInt(),
                )
                assertEquals(listOf(newest, oldest), inContext.map { it.id() })
                val sampled: JsonObject = enriched.single { it.id() == oldest }
                assertEquals(
                    2,
                    sampled
                        .getValue("totalElements")
                        .jsonPrimitive.content
                        .toInt(),
                )
                assertEquals(listOf(COVER, COVER), sampled.strings("imagesSample"))
                assertEquals(
                    0,
                    enriched
                        .single { it.id() == newest }
                        .getValue("totalElements")
                        .jsonPrimitive.content
                        .toInt(),
                )
                assertTrue("elements" !in sampled)
                assertEquals(HttpStatusCode.BadRequest, wrongContext.status)
            }
        }

    /**
     * A reader written straight into the database, as signing up 50 would meet the sign-up limit: a public list, a
     * friends list and a private one, the friends one dated so that `seededId` finds it, friends with [viewerId] when
     * [isFriend]. Its id.
     */
    private fun seedCreator(
        viewerId: String,
        isFriend: Boolean,
    ): String {
        val id: String = DocumentId.new()
        AuthTestEnvironment.execute(
            "INSERT INTO users (id, username, email, password_hash, language, created) " +
                "VALUES ('$id', 'seed$id', 'seed$id@exlibris.test', 'x', 'fr', 0)",
        )
        listOf("public" to "'{public}'", "friends" to "'{friends}'", "private" to "'{}'").forEach { (key, visibility) ->
            AuthTestEnvironment.execute(
                "INSERT INTO lists (id, creator, name, visibility, type, created) VALUES " +
                    "('${seededId("$id:$key")}', '$id', '$key', $visibility, 'work', ${created("$id:$key")})",
            )
        }
        if (isFriend) {
            val (a: String, b: String) = listOf(id, viewerId).sorted()
            AuthTestEnvironment.execute(
                "INSERT INTO relations (user_a, user_b, status, created, updated) VALUES ('$a', '$b', 'friends', 0, 0)",
            )
        }
        return id
    }

    private fun JsonObject.text(key: String): String = getValue(key).jsonPrimitive.content

    private companion object {
        const val CREATORS: Int = 50

        val seeded: MutableMap<String, Pair<String, Long>> = mutableMapOf()

        /** A seeded list's id, kept by its `creator:key`. */
        fun seededId(key: String): String = seeded.getOrPut(key) { DocumentId.new() to (seeded.size + 1L) }.first

        /** Its `created`, which grows with each list seeded, before any list made through the routes today. */
        fun created(key: String): Long = seeded.getValue(key).second
    }
}
