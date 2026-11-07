package studio.lunabee.exlibris.backend.transactions

/** A reader's side of an Échange, inventaire.io's `TransactionUserRole`, [storedName] as its `actor` says it. */
enum class TransactionRole(
    val storedName: String,
) {
    OWNER("owner"),
    REQUESTER("requester"),
}
