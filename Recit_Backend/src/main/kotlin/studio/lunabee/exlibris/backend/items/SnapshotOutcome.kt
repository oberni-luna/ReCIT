package studio.lunabee.exlibris.backend.items

/** What [SnapshotBuilder] made of an entity inventaire.io answered, or why it made nothing. */
sealed interface SnapshotOutcome {
    data class Built(
        val snapshot: EntitySnapshot,
    ) : SnapshotOutcome

    /** inventaire.io does not know the URI, or no longer does. */
    data object NotFound : SnapshotOutcome

    /** Neither an edition nor a work: inventaire.io's `allowlistedEntityTypes`. */
    data object InvalidType : SnapshotOutcome

    /** Nothing to call it by: inventaire.io's `no title found`, which no book is stored without. */
    data object NoTitle : SnapshotOutcome
}
