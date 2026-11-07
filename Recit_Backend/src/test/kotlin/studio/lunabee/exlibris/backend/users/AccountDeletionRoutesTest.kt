package studio.lunabee.exlibris.backend.users

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.auth.login
import studio.lunabee.exlibris.backend.deleteAs
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.images.TestImages
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.postRelation
import studio.lunabee.exlibris.backend.putUser
import studio.lunabee.exlibris.backend.uploadAvatar
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AccountDeletionRoutesTest {
    @Test
    fun `deleting the account answers ok, and its session, relations and avatar are gone`() =
        authTest {
            val reader: Reader = client.newReader()
            val friend: Reader = client.newReader()
            client.postRelation(reader, "request", friend)
            client.postRelation(friend, "accept", reader)
            val picture: String =
                client
                    .uploadAvatar(
                        reader,
                        TestImages.jpeg(),
                    ).json()
                    .getValue("avatar")
                    .jsonPrimitive.content
            client.putUser(reader, "picture", "\"$picture\"")
            val file = TestPostgres.imagesDirectory.resolve("users").resolve(picture.substringAfterLast('/'))
            assertTrue(Files.exists(file))

            val response: HttpResponse = client.deleteAs("/api/user", reader)

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
            assertTrue(
                response.headers
                    .getAll(HttpHeaders.SetCookie)
                    .orEmpty()
                    .any { it.contains("1970") },
            )
            assertEquals(HttpStatusCode.Unauthorized, client.getAs("/api/user", reader).status)
            assertEquals(HttpStatusCode.Unauthorized, client.getAs("/api/relations", reader).status)
            assertTrue(
                client
                    .getAs("/api/relations", friend)
                    .json()
                    .getValue("friends")
                    .jsonArray
                    .isEmpty(),
            )
            assertFalse(Files.exists(file))
            assertEquals(HttpStatusCode.NotFound, client.getAs(picture, null).status)
            assertEquals(
                0,
                AuthTestEnvironment.queryLong(
                    "SELECT count(*) FROM relations WHERE user_a = '${reader.id}' OR user_b = '${reader.id}'",
                ),
            )
            assertEquals(HttpStatusCode.Unauthorized, client.login(reader.account.username).status)
        }

    @Test
    fun `an avatar another reader also uses stays`() =
        authTest {
            val reader: Reader = client.newReader()
            val other: Reader = client.newReader()
            val picture: String =
                client
                    .uploadAvatar(
                        reader,
                        TestImages.jpeg(),
                    ).json()
                    .getValue("avatar")
                    .jsonPrimitive.content
            client.putUser(reader, "picture", "\"$picture\"")
            client.putUser(other, "picture", "\"$picture\"")

            client.deleteAs("/api/user", reader)

            assertEquals(HttpStatusCode.OK, client.getAs(picture, null).status)
            assertEquals(
                picture,
                client
                    .getAs("/api/user", other)
                    .json()
                    .getValue("picture")
                    .jsonPrimitive.content,
            )
        }

    @Test
    fun `signed out, deleting is refused`() =
        authTest {
            val response: HttpResponse =
                client.deleteAs(
                    "/api/user",
                    Reader(AuthTestEnvironment.newAccount(), "", emptyMap()),
                )

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("user/user.anonymous.json", response.bodyAsText())
        }
}
