package studio.lunabee.exlibris.backend.search

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * One hit of `/api/search`, in inventaire.io's `normalizeResult` shape. For a reader: [label] is the username,
 * [description] the bio, [image] the picture's path, and `type` the plural `users` inventaire.io sends.
 */
@Serializable
data class SearchResult(
    val id: String,
    val type: String,
    val label: String,
    val description: String? = null,
    val image: String? = null,
    @SerialName("_score")
    val score: Double,
)
