package studio.lunabee.exlibris.backend

import io.ktor.client.HttpClient
import io.ktor.client.request.delete
import io.ktor.client.request.forms.formData
import io.ktor.client.request.forms.submitFormWithBinaryData
import io.ktor.client.request.get
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.TestAccount
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.auth.sessionUser
import studio.lunabee.exlibris.backend.auth.setCookies
import studio.lunabee.exlibris.backend.auth.signup
import kotlin.test.assertEquals

/** A reader signed up for a test, with the session signing up handed them. */
data class Reader(
    val account: TestAccount,
    val id: String,
    val cookies: Map<String, String>,
)

/** Signs a new reader up; [username] when the test needs one it can search for. */
suspend fun HttpClient.newReader(username: String? = null): Reader {
    val generated: TestAccount = AuthTestEnvironment.newAccount()
    val account: TestAccount = username?.let { generated.copy(username = it) } ?: generated
    val response: HttpResponse = signup(account)
    assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
    val cookies: Map<String, String> = response.setCookies()
    return Reader(account, requireNotNull(sessionUser(cookies)), cookies)
}

suspend fun HttpClient.getAs(
    path: String,
    reader: Reader?,
): HttpResponse = get(path) { reader?.let { sendCookies(it.cookies) } }

suspend fun HttpClient.deleteAs(
    path: String,
    reader: Reader,
): HttpResponse = delete(path) { sendCookies(reader.cookies) }

/** `PUT /api/user` with [value] written as JSON: `"text"`, `true`, `[1,2]`, `null`. */
suspend fun HttpClient.putUser(
    reader: Reader,
    attribute: String,
    value: String,
): HttpResponse =
    put("/api/user") {
        contentType(ContentType.Application.Json)
        setBody("""{"attribute":"$attribute","value":$value}""")
        sendCookies(reader.cookies)
    }

suspend fun HttpClient.postRelation(
    reader: Reader,
    action: String,
    other: Reader,
): HttpResponse = postJson("/api/relations/$action", """{"user":"${other.id}"}""", reader.cookies)

/**
 * `POST /api/images/upload` of [bytes] as the apps send an avatar: one JPEG part named `avatar`. A group's picture
 * comes in a part named `picture`.
 */
suspend fun HttpClient.uploadAvatar(
    reader: Reader,
    bytes: ByteArray,
    container: String = "users",
    fieldName: String = "avatar",
): HttpResponse =
    submitFormWithBinaryData(
        url = "/api/images/upload?container=$container",
        formData =
            formData {
                append(
                    fieldName,
                    bytes,
                    Headers.build {
                        append(HttpHeaders.ContentType, "image/jpeg")
                        append(HttpHeaders.ContentDisposition, "filename=\"avatar.jpg\"")
                    },
                )
            },
    ) { sendCookies(reader.cookies) }

suspend fun HttpResponse.json(): JsonObject = Json.parseToJsonElement(bodyAsText()).jsonObject
