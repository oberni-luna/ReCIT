package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * A list as inventaire.io answers it. Its [visibility] reaches every reader who may see it, as inventaire.io's
 * listings do (unlike books and étagères). [elements] only with `with-elements`, [totalElements] and [imagesSample]
 * only when `attributes` asks for them.
 */
@Serializable
data class ListDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val name: String,
    val description: String,
    val visibility: List<String>,
    val creator: String,
    val created: Long,
    val updated: Long? = null,
    val type: String,
    val elements: List<ListElementDocument>? = null,
    val totalElements: Int? = null,
    val imagesSample: List<String>? = null,
)
