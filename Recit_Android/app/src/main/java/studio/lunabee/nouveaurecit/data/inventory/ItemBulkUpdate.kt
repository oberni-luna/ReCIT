package studio.lunabee.nouveaurecit.data.inventory

import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.OkMapDto
import studio.lunabee.nouveaurecit.network.dto.UpdateItemsDto

/** `InventoryModel.updateItems(ids:attribute:value:)`, for one item: `PUT /api/items/bulk-update`, `ok` or a throw. */
suspend fun ApiService.bulkUpdateItem(itemId: String, attribute: String, value: String) {
    val response: OkMapDto = send("/api/items/bulk-update", method = "PUT", body = UpdateItemsDto(listOf(itemId), attribute, value))
    if (!response.ok) throw NetworkError.BadResponse()
}
