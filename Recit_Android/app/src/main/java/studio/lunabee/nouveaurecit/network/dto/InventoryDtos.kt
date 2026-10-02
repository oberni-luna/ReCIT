package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class InventoryResultDto(
    val worksTree: InventoryWorkTreeDto,
    val workUriItemsMap: Map<String, List<String>> = emptyMap(),
    val totalItems: Int = 0,
)

@Serializable
data class InventoryWorkTreeDto(
    val author: Map<String, List<String>> = emptyMap(),
    val genre: Map<String, List<String>> = emptyMap(),
    val owner: Map<String, Map<String, List<String>>> = emptyMap(),
)

@Serializable
data class ItemsDto(
    val items: List<ItemDto> = emptyList(),
    val total: Int = 0,
    val offset: Int = 0,
)

@Serializable
data class PostItemResponseDto(val item: ItemDto)

@Serializable
data class ItemDto(
    @SerialName("_id") val id: String,
    @SerialName("_rev") val rev: String,
    val entity: String,
    val transaction: String,
    val details: String? = null,
    val visibility: List<String>? = null,
    val owner: String,
    val created: Double,
    val updated: Double? = null,
    val busy: Boolean? = null,
    val shelves: List<String>? = null,
    val snapshot: EntitySnapshotDto,
)

@Serializable
data class EntitySnapshotDto(
    @SerialName("entity:title") val title: String = "",
    @SerialName("entity:subtitle") val subtitle: String? = null,
    @SerialName("entity:lang") val lang: String? = null,
    @SerialName("entity:authors") val authors: String? = null,
    @SerialName("entity:image") val image: String? = null,
    @SerialName("entity:series") val series: String? = null,
    @SerialName("entity:ordinal") val ordinal: String? = null,
)

@Serializable
data class NewItemDto(
    val entity: String,
    val transaction: String,
    val visibility: List<String>,
    val shelves: List<String> = emptyList(),
)

@Serializable
data class UpdateItemsDto(
    val ids: List<String>,
    val attribute: String,
    val value: String,
)

@Serializable
data class OkMapDto(val ok: Boolean = false)
