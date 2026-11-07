package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * An item as inventaire.io answers it. [visibility] and [notes] reach the owner alone (`filterPrivateAttributes`);
 * [busy] is in the reads only, [snapshot] wherever inventaire.io adds one, not in a deletion's echo.
 */
@Serializable
data class ItemDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val entity: String,
    val transaction: String,
    val visibility: List<String>? = null,
    val details: String? = null,
    val notes: String? = null,
    val shelves: List<String>,
    val owner: String,
    val created: Long,
    val updated: Long? = null,
    val previousEntities: List<String>? = null,
    val busy: Boolean? = null,
    val snapshot: ItemSnapshot? = null,
)
