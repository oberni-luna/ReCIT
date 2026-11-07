package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.Serializable

/** `GET /api/items/inventory-view`, inventaire.io's `bundleViewData`. */
@Serializable
data class InventoryView(
    val worksTree: WorksTree,
    val workUriItemsMap: Map<String, List<String>>,
    val itemsByDate: List<String>,
    val totalItems: Int,
)
