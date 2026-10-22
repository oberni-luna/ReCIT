package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** `GET /api/items/recent-public`, read down to the one field the welcome wall needs. */
@Serializable
data class RecentPublicItemsDto(val items: List<RecentPublicItemDto> = emptyList())

@Serializable
data class RecentPublicItemDto(val snapshot: RecentPublicSnapshotDto? = null)

@Serializable
data class RecentPublicSnapshotDto(@SerialName("entity:image") val image: String? = null)
