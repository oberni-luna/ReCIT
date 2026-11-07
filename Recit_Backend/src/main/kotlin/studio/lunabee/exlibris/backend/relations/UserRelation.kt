package studio.lunabee.exlibris.backend.relations

/**
 * Where a user stands with another, seen from the user's side: inventaire.io's `userRelativeRequest`, and the
 * lists `/api/relations` answers.
 */
enum class UserRelation {
    FRIENDS,

    /** The user asked the other. */
    USER_REQUESTED,

    /** The other asked the user. */
    OTHER_REQUESTED,
    NONE,
    ;

    /** The pair's status once [userId] stands here with [otherId]. */
    fun status(
        userId: String,
        otherId: String,
    ): RelationStatus =
        when (this) {
            FRIENDS -> RelationStatus.FRIENDS
            NONE -> RelationStatus.NONE
            USER_REQUESTED -> if (userId < otherId) RelationStatus.A_REQUESTED else RelationStatus.B_REQUESTED
            OTHER_REQUESTED -> if (userId < otherId) RelationStatus.B_REQUESTED else RelationStatus.A_REQUESTED
        }

    companion object {
        /** How [userId] stands with [otherId] when their pair's status is [status]. */
        fun of(
            userId: String,
            otherId: String,
            status: RelationStatus,
        ): UserRelation =
            when (status) {
                RelationStatus.FRIENDS -> FRIENDS
                RelationStatus.NONE -> NONE
                RelationStatus.A_REQUESTED -> if (userId < otherId) USER_REQUESTED else OTHER_REQUESTED
                RelationStatus.B_REQUESTED -> if (userId < otherId) OTHER_REQUESTED else USER_REQUESTED
            }
    }
}
