package studio.lunabee.exlibris.backend.lists

import io.ktor.client.HttpClient
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.InventaireStub
import studio.lunabee.exlibris.backend.entities.StubAnswer
import studio.lunabee.exlibris.backend.entities.StubRequest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import kotlin.test.assertEquals

/** George Orwell, a `human`. */
const val ORWELL: String = "wd:Q3335"

/** A Wikidata item merged into [REDIRECT_TARGET], which inventaire.io answers it with (`by-uris.info.redirect`). */
const val REDIRECTED: String = "wd:Q20050020"

const val REDIRECT_TARGET: String = "wd:Q146866"

/** A second work, for lists holding more than one. */
const val SECOND_WORK: String = "wd:Q180736"

const val UNKNOWN_WORK: String = "wd:Q999999999"

/** The image `attributes=image` answers for every work, as inventaire.io's `/img/entities/<hash>`. */
const val COVER: String = "/img/entities/0123456789abcdef0123456789abcdef01234567"

/** inventaire.io's types: « 1984 » a work, as `entities/by-uris.info.json` has it. */
private val types: Map<String, String> =
    mapOf(WORK_1984 to "work", ORWELL to "human", REDIRECT_TARGET to "work", SECOND_WORK to "work")

/**
 * inventaire.io's `by-uris`, built from the URIs asked for in the captured shape: each known entity with its `type`
 * (and an image when `attributes=image` is asked), [REDIRECTED] redirected, anything else in `notFound`.
 */
fun entitiesAnswer(request: StubRequest): StubAnswer {
    val uris: List<String> =
        request.uri
            .substringAfter("uris=")
            .substringBefore('&')
            .split("%7C", "|")
            .map { it.replace("%3A", ":") }
    val redirects: Map<String, String> = uris.filter { it == REDIRECTED }.associateWith { REDIRECT_TARGET }
    val canonical: List<String> = uris.map { redirects[it] ?: it }
    val image: String = if ("attributes=image" in request.uri) ""","image":{"url":"$COVER"}""" else ""
    val entities: String =
        canonical.filter { it in types }.distinct().joinToString(",") { uri ->
            """"$uri":{"uri":"$uri","type":"${types.getValue(uri)}"$image}"""
        }
    val notFound: String = canonical.filter { it !in types }.joinToString(",") { "\"$it\"" }
    return StubAnswer.json(
        """{"entities":{$entities},"redirects":{${
            redirects.entries.joinToString(",") { "\"${it.key}\":\"${it.value}\"" }
        }},"notFound":[$notFound]}""",
    )
}

fun listStub(): InventaireStub = InventaireStub().apply { answer = ::entitiesAnswer }

/** `POST /api/lists` as both apps send it. */
suspend fun HttpClient.postList(
    reader: Reader,
    json: String,
): HttpResponse = postJson("/api/lists", json, reader.cookies)

/** A list created by [reader]; its id. */
suspend fun HttpClient.newList(
    reader: Reader,
    name: String = "Polars",
    visibility: String = "[]",
    type: String = "work",
): String {
    val response: HttpResponse =
        postList(reader, """{"name":"$name","description":"","visibility":$visibility,"type":"$type"}""")
    assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
    return response
        .json()
        .getValue("list")
        .jsonObject
        .id()
}

/** `PUT /api/lists/<action>`, as both apps send the element writes. */
suspend fun HttpClient.listAction(
    reader: Reader,
    action: String,
    json: String,
): HttpResponse = putJson(reader, "/api/lists/$action", json)

suspend fun HttpClient.addElements(
    reader: Reader,
    listId: String,
    vararg uris: String,
): HttpResponse = listAction(reader, "add-elements", """{"id":"$listId","uris":${uris.toList().quoted()}}""")

/** [uris] added to [listId] by [reader]; the elements created. */
suspend fun HttpClient.newElements(
    reader: Reader,
    listId: String,
    vararg uris: String,
): List<JsonObject> {
    val response: HttpResponse = addElements(reader, listId, *uris)
    assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
    return response.json().objects("createdElements")
}

/** `by-creators?with-elements=true` for [creators], as the apps sync; the lists answered. */
suspend fun HttpClient.listsOf(
    creators: List<String>,
    viewer: Reader?,
    query: String = "with-elements=true",
): List<JsonObject> =
    getAs("/api/lists/by-creators?users=${creators.joinToString("|")}&$query", viewer).json().objects("lists")

fun JsonObject.objects(key: String): List<JsonObject> = getValue(key).jsonArray.map { it.jsonObject }

fun JsonObject.elements(): List<JsonObject> = (get("elements") as? JsonArray).orEmpty().map { it.jsonObject }

fun List<String>.quoted(): String = joinToString(",", "[", "]") { "\"$it\"" }
