package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject

/**
 * inventaire.io's `GET /api/entities/by-uris` answer, read down to what a snapshot needs: the entities by URI, and
 * the redirects it followed — an `isbn:` URI to its edition, an edition merged into another.
 */
class InventaireEntities(
    private val entities: Map<String, JsonObject>,
    private val redirects: Map<String, String>,
) {
    /** The URI inventaire.io files [uri] under now. */
    fun canonical(uri: String): String = redirects[uri] ?: uri

    fun entity(uri: String): JsonObject? = entities[canonical(uri)]

    companion object {
        fun parse(text: String): InventaireEntities {
            val answer: JsonObject = Json.parseToJsonElement(text).jsonObject
            return InventaireEntities(
                entities = answer.objectAt("entities").mapValues { (_, entity) -> entity.jsonObject },
                redirects =
                    answer
                        .objectAt("redirects")
                        .mapNotNull { (from, to) ->
                            (to as? JsonPrimitive)?.takeIf { it.isString }?.let { from to it.content }
                        }.toMap(),
            )
        }

        private fun JsonObject.objectAt(key: String): JsonObject =
            when (val value = this[key]) {
                is JsonObject -> value
                is JsonArray, is JsonPrimitive, null -> JsonObject(emptyMap())
            }
    }
}
