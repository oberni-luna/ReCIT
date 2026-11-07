package studio.lunabee.exlibris.backend.relations

/**
 * `POST /api/relations/<action>`, and what each does from where the caller stands: inventaire.io's
 * `solve_intent.ts`. An action that does not fit — accepting a request that was cancelled, asking a friend — does
 * nothing and still answers `ok`, as there.
 */
enum class RelationAction(
    val path: String,
) {
    REQUEST("request"),
    CANCEL("cancel"),
    ACCEPT("accept"),
    DISCARD("discard"),
    UNFRIEND("unfriend"),
    ;

    /** Where the caller stands once done, from [current]; `null` when the action does nothing. */
    fun next(current: UserRelation): UserRelation? =
        when (this) {
            // Asking someone who has already asked me makes us friends.
            REQUEST -> {
                when (current) {
                    UserRelation.NONE -> UserRelation.USER_REQUESTED
                    UserRelation.OTHER_REQUESTED -> UserRelation.FRIENDS
                    else -> null
                }
            }

            CANCEL -> {
                UserRelation.NONE.takeIf { current == UserRelation.USER_REQUESTED }
            }

            ACCEPT -> {
                UserRelation.FRIENDS.takeIf { current == UserRelation.OTHER_REQUESTED }
            }

            DISCARD -> {
                UserRelation.NONE.takeIf { current == UserRelation.OTHER_REQUESTED }
            }

            UNFRIEND -> {
                UserRelation.NONE.takeIf { current != UserRelation.NONE }
            }
        }
}
