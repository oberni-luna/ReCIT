package studio.lunabee.exlibris.backend.transactions

import io.ktor.client.HttpClient
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.ISBN_1984
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.postItem
import studio.lunabee.exlibris.backend.json
import kotlin.test.assertEquals

/** A book of « 1984 » [owner] offers as [mode], seen by [visibility]; its id. */
suspend fun HttpClient.newOfferedBook(
    owner: Reader,
    mode: String = "lending",
    visibility: String = """["friends"]""",
    details: String? = null,
): String {
    val detailsField: String = details?.let { ""","details":"$it"""" }.orEmpty()
    val response: HttpResponse =
        postItem(
            owner,
            """{"entity":"$ISBN_1984","transaction":"$mode","visibility":$visibility$detailsField}""",
        )
    assertEquals(HttpStatusCode.Created, response.status, response.bodyAsText())
    return response
        .json()
        .getValue("item")
        .jsonObject
        .id()
}

/** `POST /api/transactions/request`, as Android sends it and as iOS's 0071 names it. */
suspend fun HttpClient.requestBook(
    reader: Reader,
    itemId: String,
    message: String = "Je peux ?",
): HttpResponse = postJson("/api/transactions/request", """{"item":"$itemId","message":"$message"}""", reader.cookies)

/** A request that succeeds; the Échange created. */
suspend fun HttpClient.newTransaction(
    reader: Reader,
    itemId: String,
): JsonObject {
    val response: HttpResponse = requestBook(reader, itemId)
    assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
    return response.json().getValue("transaction").jsonObject
}

/** `PUT /api/transactions/update-state`, as iOS sends it. */
suspend fun HttpClient.updateState(
    reader: Reader,
    transactionId: String,
    state: String,
): HttpResponse = putJson(reader, "/api/transactions/update-state", """{"state":"$state","id":"$transactionId"}""")

/** An `update-state` that succeeds; the Échange answered. */
suspend fun HttpClient.moveTo(
    reader: Reader,
    transactionId: String,
    state: String,
): JsonObject {
    val response: HttpResponse = updateState(reader, transactionId, state)
    assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
    return response.json().getValue("transaction").jsonObject
}

suspend fun HttpClient.transactionsOf(reader: Reader): List<JsonObject> =
    getAs("/api/transactions", reader)
        .json()
        .getValue("transactions")
        .jsonArray
        .map { it.jsonObject }

/** `POST /api/transactions/messages`, as iOS sends it. */
suspend fun HttpClient.postMessage(
    reader: Reader,
    transactionId: String,
    message: String,
): HttpResponse =
    postJson("/api/transactions/messages", """{"message":"$message","id":"$transactionId"}""", reader.cookies)

suspend fun HttpClient.messagesOf(
    reader: Reader,
    transactionId: String,
): List<JsonObject> =
    getAs("/api/transactions/messages?id=$transactionId", reader)
        .json()
        .getValue("messages")
        .jsonArray
        .map { it.jsonObject }

fun JsonObject.text(key: String): String = getValue(key).jsonPrimitive.content

fun JsonObject.read(side: String): Boolean =
    getValue("read")
        .jsonObject
        .getValue(side)
        .jsonPrimitive.boolean

fun JsonObject.actions(): List<String> = getValue("actions").jsonArray.map { it.jsonObject.text("action") }

fun countRows(query: String): Long = AuthTestEnvironment.queryLong(query)

/**
 * [transaction] against the transaction at [path] in [fixture]: its keys and types, and those of its `read`,
 * `snapshot` and the snapshot's parts, and of its first action.
 */
fun assertTransactionShape(
    fixture: String,
    transaction: JsonObject,
    path: (JsonObject) -> JsonObject = { it.getValue("transaction").jsonObject },
) {
    val expected: JsonObject = path(fixture(fixture))
    assertMatchesShape(expected, transaction, fixture)
    assertMatchesShape(expected.part("read"), transaction.part("read"), "read")
    assertMatchesShape(expected.part("snapshot"), transaction.part("snapshot"), "snapshot")
    listOf("item", "entity", "owner", "requester").forEach { part ->
        assertMatchesShape(
            expected.part("snapshot").part(part),
            transaction.part("snapshot").part(part),
            "snapshot.$part",
        )
    }
    assertMatchesShape(
        (expected.getValue("actions") as JsonArray)[0].jsonObject,
        (transaction.getValue("actions") as JsonArray)[0].jsonObject,
        "actions",
    )
}

private fun JsonObject.part(key: String): JsonObject = getValue(key).jsonObject
