package studio.lunabee.exlibris.backend.groups

import io.ktor.client.HttpClient
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.images.TestImages
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.uploadAvatar
import kotlin.test.assertEquals

/** A group name no other test uses: the tests share one database. Letters only, so the slug keeps all of it. */
fun uniqueGroupName(prefix: String = "Club"): String =
    "$prefix ${(1..NAME_SUFFIX_LENGTH).map { ('a'..'z').random() }.joinToString("")}"

private const val NAME_SUFFIX_LENGTH: Int = 8

/** `POST /api/groups` as the apps send it. */
suspend fun HttpClient.postGroup(
    reader: Reader,
    json: String,
): HttpResponse =
    post("/api/groups") {
        contentType(ContentType.Application.Json)
        setBody(json)
        sendCookies(reader.cookies)
    }

/** A group created by [creator], its id. */
suspend fun HttpClient.newGroup(
    creator: Reader,
    name: String = uniqueGroupName(),
    open: Boolean = false,
    searchable: Boolean = true,
): String {
    val response: HttpResponse =
        postGroup(creator, """{"name":"$name","description":"","searchable":$searchable,"open":$open}""")
    assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
    return response
        .json()
        .getValue("_id")
        .jsonPrimitive.content
}

/** `PUT /api/groups/<action>` with `{group, user?}`, as the apps send it. */
suspend fun HttpClient.groupAction(
    reader: Reader,
    action: String,
    groupId: String,
    other: Reader? = null,
): HttpResponse =
    putJson(
        reader,
        "/api/groups/$action",
        other?.let { """{"group":"$groupId","user":"${it.id}"}""" } ?: """{"group":"$groupId"}""",
    )

/** `PUT /api/groups/update-settings` with [value] written as JSON. */
suspend fun HttpClient.updateGroup(
    reader: Reader,
    groupId: String,
    attribute: String,
    value: String,
): HttpResponse =
    putJson(reader, "/api/groups/update-settings", """{"group":"$groupId","attribute":"$attribute","value":$value}""")

suspend fun HttpClient.putJson(
    reader: Reader,
    path: String,
    json: String,
): HttpResponse =
    put(path) {
        contentType(ContentType.Application.Json)
        setBody(json)
        sendCookies(reader.cookies)
    }

/** The group as `by-id` answers it, signed out. */
suspend fun HttpClient.groupById(groupId: String): JsonObject =
    getAs("/api/groups/by-id?id=$groupId", null).json().getValue("group").jsonObject

/** The users of [list] in [group], in order. */
fun JsonObject.usersIn(list: String): List<String> =
    getValue(list).jsonArray.map {
        it.jsonObject
            .getValue("user")
            .jsonPrimitive.content
    }

suspend fun HttpResponse.errorName(): String = json().getValue("error_name").jsonPrimitive.content

fun JsonObject.string(key: String): String = getValue(key).jsonPrimitive.content

/** A picture uploaded into `groups`, as Réglages du groupe sends it, its path. */
suspend fun HttpClient.groupPicture(reader: Reader): String =
    uploadAvatar(reader, TestImages.jpeg(), container = "groups", fieldName = "picture").json().string("picture")
