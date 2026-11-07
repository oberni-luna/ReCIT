package studio.lunabee.exlibris.backend.images

import io.ktor.client.request.forms.formData
import io.ktor.client.request.forms.submitFormWithBinaryData
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsBytes
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.uploadAvatar
import java.security.MessageDigest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals

class ImagesRoutesTest {
    @Test
    fun `an uploaded JPEG is answered by its path, which serves the same bytes`() =
        authTest {
            val reader: Reader = client.newReader()
            val jpeg: ByteArray = TestImages.jpeg()

            val response: HttpResponse = client.uploadAvatar(reader, jpeg)

            assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
            assertMatchesFixture("images/upload.derived.json", response.bodyAsText())
            val path: String =
                response
                    .json()
                    .getValue("avatar")
                    .jsonPrimitive.content
            assertEquals("/img/users/${MessageDigest.getInstance("SHA-1").digest(jpeg).toHexString()}", path)
            val image: HttpResponse = client.getAs(path, null)
            assertEquals(HttpStatusCode.OK, image.status)
            assertEquals(ContentType.Image.JPEG, image.contentType()?.withoutParameters())
            assertEquals("public, max-age=31536000, immutable", image.headers[HttpHeaders.CacheControl])
            assertContentEquals(jpeg, image.bodyAsBytes())
            val sized: HttpResponse = client.getAs(path.replace("/img/users/", "/img/users/64x64/"), null)
            assertContentEquals(jpeg, sized.bodyAsBytes())
        }

    @Test
    fun `a file that is not an image, no file and a wrong container are refused`() =
        authTest {
            val reader: Reader = client.newReader()

            val text: HttpResponse = client.uploadAvatar(reader, "<script>alert(1)</script>".toByteArray())
            val noFile: HttpResponse =
                client.submitFormWithBinaryData("/api/images/upload?container=users", formData { append("a", "b") }) {
                    sendCookies(reader.cookies)
                }
            val json: HttpResponse =
                client.post("/api/images/upload?container=users") {
                    contentType(ContentType.Application.Json)
                    setBody("{}")
                    sendCookies(reader.cookies)
                }
            val container: HttpResponse = client.uploadAvatar(reader, TestImages.jpeg(), container = "books")

            assertEquals(
                "invalid image",
                text
                    .json()
                    .getValue("message")
                    .jsonPrimitive.content,
            )
            assertEquals(
                "no file provided",
                noFile
                    .json()
                    .getValue("message")
                    .jsonPrimitive.content,
            )
            assertEquals(
                "invalid content-type",
                json
                    .json()
                    .getValue("message")
                    .jsonPrimitive.content,
            )
            assertEquals(HttpStatusCode.BadRequest, container.status)
        }

    @Test
    fun `signed out, an upload is refused`() =
        authTest {
            val reader: Reader = client.newReader()

            val response: HttpResponse = client.uploadAvatar(reader.copy(cookies = emptyMap()), TestImages.jpeg())

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("user/user.anonymous.json", response.bodyAsText())
        }

    @Test
    fun `an unknown image is not found, a malformed path refused as inventaire refuses it`() =
        authTest {
            val unknown: HttpResponse = client.getAs("/img/users/${"0".repeat(40)}", null)
            val malformed: HttpResponse = client.getAs("/img/users/zzz", null)
            val climbing: HttpResponse = client.getAs("/img/users/..%2F..%2Fetc%2Fpasswd", null)

            assertEquals(HttpStatusCode.NotFound, unknown.status)
            assertEquals(HttpStatusCode.BadRequest, malformed.status)
            assertMatchesFixture("images/img.invalid-path.json", malformed.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, climbing.status)
        }

    @Test
    fun `the gravatar address is built from the account's address`() =
        authTest {
            val reader: Reader = client.newReader()

            val response: HttpResponse = client.getAs("/api/images/gravatar", reader)

            assertMatchesFixture("images/gravatar.derived.json", response.bodyAsText())
            val hash: String =
                MessageDigest
                    .getInstance("SHA-256")
                    .digest(
                        reader.account.email
                            .lowercase()
                            .toByteArray(),
                    ).toHexString()
            assertEquals(
                "https://gravatar.com/avatar/$hash?d=404&s=500",
                response
                    .json()
                    .getValue("url")
                    .jsonPrimitive.content,
            )
        }

    @Test
    fun `signed out, the gravatar is refused as inventaire refuses it`() =
        authTest {
            val response: HttpResponse = client.getAs("/api/images/gravatar", null)

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("images/gravatar.anonymous.json", response.bodyAsText())
        }
}
