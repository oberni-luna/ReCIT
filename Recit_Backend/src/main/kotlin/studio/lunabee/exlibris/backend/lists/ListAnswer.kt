package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.Serializable

/** `create`, `update` and `remove-elements`: the list as it now is, without its elements. */
@Serializable
data class ListAnswer(
    val list: ListDocument,
)
