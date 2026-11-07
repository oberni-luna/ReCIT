package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.Serializable

/** `delete`: the lists removed, and their elements with them. */
@Serializable
data class ListsDeletion(
    val ok: Boolean = true,
    val lists: List<ListDocument>,
    val elements: List<ListElementDocument>,
)
