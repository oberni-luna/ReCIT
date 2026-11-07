package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** A reader in an Échange's `snapshot`, inventaire.io's `userAttributes.snapshot`. */
@Serializable
data class TransactionUserSnapshot(
    val username: String,
    val picture: String? = null,
)
