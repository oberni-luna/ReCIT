package studio.lunabee.nouveaurecit.data.transactions

import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.UserEntity

/**
 * A copy someone else offers, which the « … » menu proposes to ask for: « Emprunter à Anne »,
 * « Acheter à Paul », « Récupérer de Léa ». An inventoried copy has no [wording], so no target:
 * it cannot be requested, the server says so (`this item can't be requested`).
 */
data class TransactionRequestTarget(
    val itemId: String,
    val ownerName: String,
    val wording: TransactionRequestWording,
) {
    companion object {
        /** `borrowableItems`: as many owners as the menu can hold without becoming a list of its own. */
        const val MAX_TARGETS: Int = 5

        /**
         * `BookActions.borrowableItems`: other people's copies on offer — [othersCopies] holds none
         * of mine —, one per owner, the first [MAX_TARGETS] of them. A copy whose owner is not in
         * the store has no name to word the line with, and is left out.
         */
        fun of(othersCopies: List<ItemRow>): List<TransactionRequestTarget> = othersCopies
            .asSequence()
            .filter { it.owner != null && TransactionRequestWording.of(it.item.transaction) != null }
            .distinctBy { it.item.ownerId }
            .mapNotNull { row ->
                val owner: UserEntity = row.owner ?: return@mapNotNull null
                val wording: TransactionRequestWording = TransactionRequestWording.of(row.item.transaction) ?: return@mapNotNull null
                TransactionRequestTarget(row.item.id, owner.username, wording)
            }
            .take(MAX_TARGETS)
            .toList()
    }
}
