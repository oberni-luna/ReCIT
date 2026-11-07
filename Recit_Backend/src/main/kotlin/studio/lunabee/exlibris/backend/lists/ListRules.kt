package studio.lunabee.exlibris.backend.lists

import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/** inventaire.io's sanitization of the list routes' parameters, and `models/validations/listing.ts`. */
object ListRules {
    private const val NAME_MAX_LENGTH: Int = 128
    private const val TEXT_MAX_LENGTH: Int = 5000
    private val entityUriPattern: Regex = Regex("^(wd:Q[1-9][0-9]*|inv:[0-9a-f]{32})$")
    private val attributes: List<String> = listOf("total", "images")

    /** A list's or an element's id, sent as [name]: inventaire.io's `couchUuid`. */
    fun id(
        body: JsonBody,
        name: String = "id",
    ): String = body.string(name).also { if (!DocumentId.isValid(it)) throw ApiException.invalidParameter(name, it) }

    fun name(name: String?): String =
        name?.takeIf { it.isNotEmpty() && it.length <= NAME_MAX_LENGTH }
            ?: throw ApiException.invalidParameter("name", name.orEmpty())

    /** Absent or empty is `""`. */
    fun description(description: String?): String = text("description", description)

    /** `""` and `null` alike clear a comment, as inventaire.io's `updateElementDoc` does. */
    fun comment(comment: String?): String = text("comment", comment)

    /** Absent is a list of works, inventaire.io's default. */
    fun type(type: String?): ListType {
        val name: String = type ?: return ListType.WORK
        return ListType.from(name) ?: throw ApiException(
            HttpStatusCode.BadRequest,
            "invalid type: $name (possible values: ${ListType.entries.joinToString(", ") { it.storedName }})",
        )
    }

    /** `uris`: an array, or URIs joined by `|`, deduplicated; each a `wd:` or `inv:` entity URI. */
    fun uris(body: JsonBody): List<String> {
        val value: JsonElement =
            body.element("uris")?.takeUnless { it is JsonNull }
                ?: throw ApiException.missingParameter(ParameterPlace.BODY, "uris")
        val uris: List<String> =
            ((value as? JsonPrimitive)?.takeIf { it.isString }?.content?.split('|') ?: body.optionalStringList("uris"))
                .orEmpty()
                .map { it.trim() }
                .distinct()
        val refusal: ApiException? =
            if (uris.isEmpty()) {
                ApiException(HttpStatusCode.BadRequest, "uris array can't be empty")
            } else {
                uris.firstOrNull { !entityUriPattern.matches(it) }?.let { ApiException.invalidParameter("uri", it) }
            }
        refusal?.let { throw it }
        return uris
    }

    /** `by-creators`' `context`: a visibility key, which [isKey] tells. */
    fun context(
        context: String?,
        isKey: (String) -> Boolean,
    ): String? = context?.also { if (!isKey(it)) throw ApiException(HttpStatusCode.BadRequest, "invalid context") }

    /** `by-creators`' `attributes`, joined by `|`: `total`, `images`. */
    fun attributes(attributes: String?): Set<String> {
        val names: List<String> = attributes?.split('|')?.map { it.trim() }.orEmpty()
        names.firstOrNull { it !in this.attributes }?.let {
            throw ApiException(
                HttpStatusCode.BadRequest,
                "invalid attributes: $it (possible values: ${this.attributes.joinToString(", ")})",
            )
        }
        return names.toSet()
    }

    private fun text(
        name: String,
        value: String?,
    ): String = value.orEmpty().takeIf { it.length <= TEXT_MAX_LENGTH } ?: throw ApiException.invalidParameter(name)
}
