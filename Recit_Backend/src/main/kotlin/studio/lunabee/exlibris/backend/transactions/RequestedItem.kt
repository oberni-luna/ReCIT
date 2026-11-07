package studio.lunabee.exlibris.backend.transactions

import studio.lunabee.exlibris.backend.items.TransactionMode

/** A book someone asks for, with whether they can see it and whether an Échange holds it `busy`. */
data class RequestedItem(
    val id: String,
    val owner: String,
    val entity: String,
    val mode: TransactionMode,
    val details: String?,
    val isVisible: Boolean,
    val isBusy: Boolean,
)
