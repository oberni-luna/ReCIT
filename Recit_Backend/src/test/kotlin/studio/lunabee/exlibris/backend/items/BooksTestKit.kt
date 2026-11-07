package studio.lunabee.exlibris.backend.items

import io.ktor.client.HttpClient
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.InventaireStub
import studio.lunabee.exlibris.backend.entities.StubAnswer
import studio.lunabee.exlibris.backend.entities.StubRequest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.postRelation
import kotlin.test.assertEquals

/** « 1984 » in Folio, the edition the tests file, as the scanner sends it. */
const val ISBN_1984: String = "isbn:9782070368228"

/** What inventaire.io redirects [ISBN_1984] to, the URI the books are stored under. */
const val EDITION_1984: String = "inv:1917e3d856a752b75e2757433111f837"

const val WORK_1984: String = "wd:Q208460"

const val UNKNOWN_EDITION: String = "inv:0123456789abcdef0123456789abcdef"

/** inventaire.io as captured: « 1984 » and its graph for any read naming it, nothing found for anything else. */
fun bookAnswer(request: StubRequest): StubAnswer =
    if ("9782070368228" in request.uri || EDITION_1984 in request.uri) {
        StubAnswer.json(FixtureAssertions.read("entities/by-uris.isbn-9782070368228.relatives.json"))
    } else {
        StubAnswer.json(FixtureAssertions.read("entities/by-uris.not-found.json"))
    }

fun bookStub(): InventaireStub = InventaireStub().apply { answer = ::bookAnswer }

suspend fun HttpClient.postItem(
    reader: Reader,
    json: String,
): HttpResponse = postJson("/api/items", json, reader.cookies)

/** A book of « 1984 » created by [reader], as the apps create one; the item answered. */
suspend fun HttpClient.newBook(
    reader: Reader,
    visibility: String = "[]",
): JsonObject {
    val response: HttpResponse =
        postItem(
            reader,
            """{"entity":"$ISBN_1984","transaction":"inventorying","visibility":$visibility,"shelves":[]}""",
        )
    assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
    return response.json().getValue("item").jsonObject
}

/** `GET /api/items/by-ids` as [reader], or signed out; the ids of the books answered. */
suspend fun HttpClient.visibleItems(
    ids: List<String>,
    reader: Reader?,
): List<JsonObject> =
    getAs("/api/items/by-ids?ids=${ids.joinToString("|")}", reader)
        .json()
        .getValue("items")
        .jsonArray
        .map { it.jsonObject }

suspend fun HttpClient.bulkUpdate(
    reader: Reader,
    json: String,
): HttpResponse = putJson(reader, "/api/items/bulk-update", json)

suspend fun HttpClient.deleteItems(
    reader: Reader,
    ids: List<String>,
): HttpResponse = postJson("/api/items/delete", """{"ids":${ids.toJsonArray()}}""", reader.cookies)

suspend fun HttpClient.inventoryView(
    query: String,
    reader: Reader?,
): HttpResponse = getAs("/api/items/inventory-view?$query", reader)

/** `POST /api/shelves?action=<action>`, as both apps send every shelf write. */
suspend fun HttpClient.shelfAction(
    reader: Reader,
    action: String,
    json: String,
): HttpResponse = postJson("/api/shelves?action=$action", json, reader.cookies)

/** An étagère created by [reader]; its id. */
suspend fun HttpClient.newShelf(
    reader: Reader,
    name: String = "Lus",
    visibility: String = "[]",
): String {
    val response: HttpResponse = shelfAction(reader, "create", """{"name":"$name","visibility":$visibility}""")
    assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
    return response
        .json()
        .getValue("shelf")
        .jsonObject
        .id()
}

/** [a] and [b] friends, as Réseau makes them: a request, then its acceptance. */
suspend fun HttpClient.befriend(
    a: Reader,
    b: Reader,
) {
    postRelation(a, "request", b)
    postRelation(b, "accept", a)
}

fun JsonObject.id(): String = getValue("_id").jsonPrimitive.content

fun JsonObject.strings(key: String): List<String> = (get(key) as? JsonArray).orEmpty().map { it.jsonPrimitive.content }

fun List<String>.toJsonArray(): String = joinToString(",", "[", "]") { "\"$it\"" }

suspend fun HttpClient.postJsonAnonymously(
    path: String,
    json: String,
): HttpResponse = postJson(path, json)
