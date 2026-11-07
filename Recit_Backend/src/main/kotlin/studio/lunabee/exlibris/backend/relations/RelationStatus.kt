package studio.lunabee.exlibris.backend.relations

/**
 * A `relations` row's `status`, as inventaire.io stores it: about the pair, the smaller id being `a`.
 * [UserRelation] is the same seen from one side.
 */
enum class RelationStatus(
    val storedName: String,
) {
    FRIENDS("friends"),
    A_REQUESTED("a-requested"),
    B_REQUESTED("b-requested"),
    NONE("none"),
    ;

    companion object {
        fun of(storedName: String): RelationStatus =
            requireNotNull(
                entries.firstOrNull { it.storedName == storedName },
            ) { "unknown relation status $storedName" }
    }
}
