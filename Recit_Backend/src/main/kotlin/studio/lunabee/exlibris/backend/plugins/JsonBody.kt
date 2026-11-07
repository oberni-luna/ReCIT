package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpStatusCode
import io.ktor.server.application.ApplicationCall
import io.ktor.server.request.receiveText
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull

/** A request's JSON object, read with inventaire.io's sanitizer's errors: missing and invalid parameters. */
class JsonBody(
    private val fields: JsonObject,
) {
    fun string(name: String): String {
        val value: JsonElement? = fields[name]
        return when {
            value == null || value is JsonNull -> throw ApiException.missingParameter(ParameterPlace.BODY, name)
            value is JsonPrimitive && value.isString -> value.content
            else -> throw ApiException.invalidParameter(name, value.toString())
        }
    }

    /** [name]'s text, or `null` when it is absent or `null`. */
    fun optionalString(name: String): String? =
        when (val value: JsonElement? = fields[name]) {
            null, JsonNull -> null
            is JsonPrimitive if value.isString -> value.content
            else -> throw ApiException.invalidParameter(name, value.toString())
        }

    /** [name]'s array of texts, or `null` when it is absent or `null`. */
    fun optionalStringList(name: String): List<String>? =
        when (val value: JsonElement? = fields[name]) {
            null, JsonNull -> null
            else -> value.stringList() ?: throw ApiException.invalidParameter(name, value.toString())
        }

    /** inventaire.io's `generic: 'boolean'`: `true` or `"true"`; absent is `false`. */
    fun flag(name: String): Boolean =
        when (val value: JsonElement? = fields[name]) {
            null, JsonNull -> false
            is JsonPrimitive if !value.isString && value.booleanOrNull != null -> value.boolean
            is JsonPrimitive if value.isString && value.content in booleanTexts -> value.content.toBoolean()
            else -> throw ApiException.invalidParameter(name, value.toString())
        }

    /** inventaire.io's `couchUuids`: an array of ids, or ids joined by `|`; see [DocumentIds.parse]. */
    fun ids(name: String): List<String> {
        val value: JsonElement =
            fields[name]?.takeUnless { it is JsonNull }
                ?: throw ApiException.missingParameter(ParameterPlace.BODY, name)
        val ids: List<String> =
            (value as? JsonPrimitive)?.takeIf { it.isString }?.content?.split('|')
                ?: value.stringList()
                ?: throw ApiException.invalidParameter(name, value.toString())
        return DocumentIds.parse(ids, name)
    }

    /** [name]'s value as sent, `JsonNull` included; `null` only when the key is absent. */
    fun element(name: String): JsonElement? = fields[name]

    private fun JsonElement.stringList(): List<String>? =
        (this as? JsonArray)?.map { element ->
            (element as? JsonPrimitive)?.takeIf { it.isString }?.content ?: return null
        }

    private companion object {
        val booleanTexts: Set<String> = setOf("true", "false")
    }
}

/** An empty body is an empty object, as Express's body parser leaves it; anything but an object is refused. */
suspend fun ApplicationCall.receiveJsonBody(): JsonBody {
    val text: String = receiveText()
    val element: JsonElement? =
        try {
            Json.parseToJsonElement(text.ifBlank { "{}" })
        } catch (error: SerializationException) {
            throw ApiException(HttpStatusCode.BadRequest, "body should be an object", cause = error)
        }
    return (element as? JsonObject)?.let(::JsonBody)
        ?: throw ApiException(HttpStatusCode.BadRequest, "body should be an object")
}

fun ApplicationCall.queryParameter(name: String): String =
    request.queryParameters[name] ?: throw ApiException.missingParameter(ParameterPlace.QUERY, name)

/** A query's ids joined by `|`, inventaire.io's `couchUuids`; see [DocumentIds.parse]. */
fun ApplicationCall.queryIds(name: String): List<String> = DocumentIds.parse(queryParameter(name).split('|'), name)

/** A query's `generic: 'boolean'`: only `true` is true. */
fun ApplicationCall.queryFlag(name: String): Boolean = request.queryParameters[name] == "true"

/** A query's optional non-negative integer, inventaire.io's `limit` and `offset`. */
fun ApplicationCall.queryCount(name: String): Int? =
    request.queryParameters[name]?.let { text ->
        text.toIntOrNull()?.takeIf { it >= 0 } ?: throw ApiException.invalidParameter(name, text)
    }
