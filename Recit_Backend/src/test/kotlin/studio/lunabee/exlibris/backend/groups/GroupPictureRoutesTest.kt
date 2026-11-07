package studio.lunabee.exlibris.backend.groups

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsBytes
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.images.TestImages
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.uploadAvatar
import java.security.MessageDigest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals

class GroupPictureRoutesTest {
    @Test
    fun `a picture uploaded into groups is answered as img groups, which serves the same bytes`() =
        authTest {
            val reader: Reader = client.newReader()
            val jpeg: ByteArray = TestImages.jpeg()

            val response: HttpResponse = client.uploadAvatar(reader, jpeg, container = "groups", fieldName = "picture")

            assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
            assertMatchesFixture("images/upload.groups.derived.json", response.bodyAsText())
            val path: String = "/img/groups/${MessageDigest.getInstance("SHA-1").digest(jpeg).toHexString()}"
            assertEquals(path, response.json().string("picture"))
            assertContentEquals(jpeg, client.getAs(path, null).bodyAsBytes())
            assertContentEquals(
                jpeg,
                client.getAs(path.replace("/img/groups/", "/img/groups/64x64/"), null).bodyAsBytes(),
            )
        }

    @Test
    fun `an invalid group image path keeps inventaire's words`() =
        authTest {
            val response: HttpResponse = client.getAs("/img/groups/zzz", null)

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("images/img-groups.invalid-path.json", response.bodyAsText())
        }
}
