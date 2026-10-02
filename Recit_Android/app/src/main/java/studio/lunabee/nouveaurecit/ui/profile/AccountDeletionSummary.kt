package studio.lunabee.nouveaurecit.ui.profile

/**
 * `Model/UserData/AccountDeletionSummary.swift`: what deleting the account costs, counted before it
 * is spent — from the local store, so no spinner stands in front of the warning.
 *
 * The iOS type has a fourth count, the transactions in progress, and the sentence about other
 * people it leads to. Transactions are not ported to Android, so neither is that line.
 */
data class AccountDeletionSummary(
    val books: Int,
    val shelves: Int,
    val lists: Int,
) {
    /** The order of the cases is the order the screen reads them in. */
    enum class Kind { Books, Shelves, Lists }

    data class Line(val kind: Kind, val count: Int)

    /** One line per thing there is something of: zeroes are dropped, not drawn as « 0 étagère ». */
    val lines: List<Line>
        get() = Kind.entries.mapNotNull { kind ->
            val count: Int = count(kind)
            if (count > 0) Line(kind, count) else null
        }

    /** Nothing to lose: the screen says what will happen instead of listing what will go. */
    val isEmpty: Boolean
        get() = lines.isEmpty()

    private fun count(kind: Kind): Int = when (kind) {
        Kind.Books -> books
        Kind.Shelves -> shelves
        Kind.Lists -> lists
    }
}
