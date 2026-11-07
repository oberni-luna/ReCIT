package studio.lunabee.exlibris.backend.shelves

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * A shelf as inventaire.io answers it. [visibility] reaches the owner alone; [items], the ids of the books on it the
 * caller may see, only where inventaire.io adds them (`with-items`, `add-items`, `remove-items`, `delete`).
 */
@Serializable
data class ShelfDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val name: String,
    val description: String,
    val visibility: List<String>? = null,
    val owner: String,
    val color: String? = null,
    val created: Long,
    val updated: Long? = null,
    val items: List<String>? = null,
)
