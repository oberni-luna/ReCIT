package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.db.DocumentId

/** inventaire.io's `couchUuids` parameter, read from a body ([JsonBody.ids]) or a query ([queryIds]). */
object DocumentIds {
    /**
     * [values] deduplicated, each a document id. inventaire.io's errors: `ids array can't be empty`, and an invalid
     * element named in the singular — `invalid id: x`, `invalid item: x`, `invalid shelf: x`.
     */
    fun parse(
        values: List<String>,
        name: String,
    ): List<String> {
        val ids: List<String> = values.map { it.trim() }.filter { it.isNotEmpty() }.distinct()
        if (ids.isEmpty()) throw ApiException(HttpStatusCode.BadRequest, "$name array can't be empty")
        ids.firstOrNull { !DocumentId.isValid(it) }?.let { throw ApiException.invalidParameter(singular(name), it) }
        return ids
    }

    private fun singular(name: String): String =
        when (name) {
            "shelves" -> "shelf"
            else -> name.removeSuffix("s")
        }
}
