package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ShelvesResponseDto(val shelves: Map<String, ShelfDto> = emptyMap())

@Serializable
data class ShelvesWithItemsResponseDto(val shelves: Map<String, ShelfWithItemsDto> = emptyMap())

@Serializable
data class ShelfWithItemsDto(
    @SerialName("_id") val id: String,
    val items: List<String>? = null,
)

@Serializable
data class ShelfResponseDto(val shelf: ShelfDto)

@Serializable
data class ShelfDto(
    @SerialName("_id") val id: String,
    @SerialName("_rev") val rev: String = "",
    val name: String,
    val description: String? = null,
    val owner: String,
    val visibility: List<String>? = null,
    val color: String? = null,
    val created: Double = 0.0,
    val updated: Double? = null,
)

@Serializable
data class NewShelfDto(val name: String, val description: String? = null, val visibility: List<String>)

@Serializable
data class UpdateShelfDto(
    val shelf: String,
    val name: String,
    val description: String,
    val visibility: List<String>,
)

@Serializable
data class ShelfItemsDto(val id: String, val items: List<String>)

@Serializable
data class ListsDto(val total: Int = 0, val lists: List<ListDto> = emptyList())

@Serializable
data class ListDto(
    @SerialName("_id") val id: String,
    @SerialName("_rev") val rev: String = "",
    val name: String,
    val description: String = "",
    val created: Double = 0.0,
    val updated: Double? = null,
    val visibility: List<String> = emptyList(),
    val type: String = "work",
    val elements: List<ListElementDto>? = null,
)

@Serializable
data class ListElementDto(
    @SerialName("_id") val id: String,
    @SerialName("_rev") val rev: String = "",
    val list: String = "",
    val uri: String,
    val ordinal: String = "0",
    val created: Double = 0.0,
    val updated: Double? = null,
    val comment: String? = null,
)

@Serializable
data class NewListDto(
    val id: String? = null,
    val name: String,
    val description: String,
    val visibility: List<String>,
    val type: String? = null,
)

@Serializable
data class NewListResponseDto(val list: ListDto)

@Serializable
data class AddToListDto(val id: String, val uris: List<String>)

@Serializable
data class AddToListResponseDto(val ok: Boolean = false, val createdElements: List<ListElementDto> = emptyList())

@Serializable
data class DeleteListElementsDto(val id: String, val uris: List<String>)

@Serializable
data class RemoveElementsResponseDto(val list: ListDto? = null)

@Serializable
data class UpdateListElementDto(val id: String, val comment: String)
