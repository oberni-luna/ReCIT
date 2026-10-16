package studio.lunabee.nouveaurecit.data.sorting

/**
 * `SortApplyFailure`: why an apply stopped, when the reason is the app's own state rather than the
 * network's.
 *
 * Spelled out rather than folded into `NetworkError` because the recovery differs: a network failure is
 * worth pressing « Enregistrer » again, a library that moved under the run has to be reopened so the
 * snapshot is taken afresh. Carries the étagère's name and no copy: the screen localizes it.
 */
sealed class SortApplyFailure(val shelfName: String) : Exception("Sorting apply stopped on « $shelfName »") {
    /** The étagère the plan was going to write to is no longer in the store. */
    class ShelfNoLongerExists(shelfName: String) : SortApplyFailure(shelfName)

    /** None of the books the plan was going to file are in the inventory any more. */
    class BooksNoLongerInInventory(shelfName: String) : SortApplyFailure(shelfName)
}
