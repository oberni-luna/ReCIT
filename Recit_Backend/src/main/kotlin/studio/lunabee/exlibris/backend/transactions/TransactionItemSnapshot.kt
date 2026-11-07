package studio.lunabee.exlibris.backend.transactions

import kotlinx.serialization.Serializable

/** The book's `snapshot.item`, inventaire.io's `itemSnapshotAttributes`: its entity and its Commentaire. */
@Serializable
data class TransactionItemSnapshot(
    val entity: String,
    val details: String? = null,
)
