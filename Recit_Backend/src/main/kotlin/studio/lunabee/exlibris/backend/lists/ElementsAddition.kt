package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.Serializable

/** `add-elements`: the elements created, and those the list already held, which nothing replaced. */
@Serializable
data class ElementsAddition(
    val ok: Boolean = true,
    val createdElements: List<ListElementDocument>,
    val alreadyInList: List<ListElementDocument>,
)
