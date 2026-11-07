package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** A list's element as inventaire.io answers it: [comment] once one was written, [previousUris] once redirected. */
@Serializable
data class ListElementDocument(
    @SerialName("_id")
    val id: String,
    @SerialName("_rev")
    val rev: String,
    val list: String,
    val uri: String,
    val ordinal: String,
    val created: Long,
    val updated: Long? = null,
    val comment: String? = null,
    val previousUris: List<String>? = null,
)
