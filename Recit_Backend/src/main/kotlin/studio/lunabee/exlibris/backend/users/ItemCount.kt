package studio.lunabee.exlibris.backend.users

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** One section of a user's `snapshot`: how many books a viewer of that section may see, and the latest one's date. */
@Serializable
data class ItemCount(
    @SerialName("items:count")
    val count: Int = 0,
    @SerialName("items:last-add")
    val lastAdd: Long? = null,
)
