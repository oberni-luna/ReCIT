package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

// Reading an entity of inventaire.io's `by-uris` answer, for [SnapshotBuilder].

private const val MULTIPLE_LANGUAGES: String = "mul"
private const val ENGLISH: String = "en"

internal fun JsonObject.uri(): String = requireNotNull(text("uri")) { "an entity inventaire.io sent has no uri" }

internal fun JsonObject.text(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

/** The values of [property], simplified claims as `by-uris` sends them. */
internal fun JsonObject.claims(property: String): List<String> =
    ((this["claims"] as? JsonObject)?.get(property) as? JsonArray)
        .orEmpty()
        .mapNotNull { (it as? JsonPrimitive)?.content }

/** `getBestLangValue` on its labels: [lang], `mul`, [originalLang], `en`, then whichever language comes first. */
internal fun JsonObject.label(
    lang: String?,
    originalLang: String?,
): String? {
    val labels: JsonObject = this["labels"] as? JsonObject ?: return null
    val order: List<String> = listOfNotNull(lang, MULTIPLE_LANGUAGES, originalLang, ENGLISH) + labels.keys
    return order.distinct().firstNotNullOfOrNull { labels.text(it)?.takeIf { label -> label.isNotEmpty() } }
}
