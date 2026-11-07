package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** `by-creators`: one page of the lists the caller may see, how many there are, and where the next page starts. */
@Serializable
data class ListsPage(
    val lists: List<ListDocument>,
    val total: Int,
    @SerialName("continue")
    val next: Int? = null,
)
