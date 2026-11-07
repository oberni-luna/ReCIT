package studio.lunabee.exlibris.backend.shelves

import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/** inventaire.io's `models/validations/shelf.ts`, and its defaults for what is left empty. */
object ShelfRules {
    private const val NAME_MAX_LENGTH: Int = 128
    private const val DESCRIPTION_MAX_LENGTH: Int = 5000
    private val colorPattern: Regex = Regex("^#[0-9a-f]{6}$")

    /** The étagère `update` is about: `id`, or the legacy `shelf` the apps send. */
    fun id(body: JsonBody): String =
        body.optionalString("id") ?: body.optionalString("shelf")
            ?: throw ApiException.missingParameter(ParameterPlace.BODY, "id")

    /** [ids], each an étagère id: inventaire.io's `invalid id: x`. */
    fun ids(ids: List<String>): List<String> {
        ids.firstOrNull { !DocumentId.isValid(it) }?.let { throw ApiException.invalidParameter("id", it) }
        return ids
    }

    fun name(name: String?): String =
        name?.takeIf { it.isNotEmpty() && it.length <= NAME_MAX_LENGTH }
            ?: throw ApiException.invalidParameter("name", name.orEmpty())

    /** Absent or empty is `""`. */
    fun description(description: String?): String =
        description.orEmpty().takeIf { it.length <= DESCRIPTION_MAX_LENGTH }
            ?: throw ApiException.invalidParameter("description", description.orEmpty())

    fun color(color: String): String =
        color.takeIf(colorPattern::matches) ?: throw ApiException.invalidParameter("color", color)
}
