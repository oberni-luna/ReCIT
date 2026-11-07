package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpStatusCode
import io.ktor.server.application.ApplicationCall
import io.ktor.server.request.receiveText
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

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

    /** [name]'s value as sent, `JsonNull` included; `null` only when the key is absent. */
    fun element(name: String): JsonElement? = fields[name]
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
