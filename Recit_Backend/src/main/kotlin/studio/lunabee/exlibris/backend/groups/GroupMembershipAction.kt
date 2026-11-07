package studio.lunabee.exlibris.backend.groups

/**
 * `PUT /api/groups/<action>`, inventaire.io's `members_actions.ts`. The five that are about someone else carry a
 * `user` next to the `group` (`groupActionsWithOtherUser`).
 */
enum class GroupMembershipAction(
    val path: String,
    val targetsAnotherUser: Boolean,
) {
    INVITE("invite", targetsAnotherUser = true),
    ACCEPT("accept", targetsAnotherUser = false),
    DECLINE("decline", targetsAnotherUser = false),
    REQUEST("request", targetsAnotherUser = false),
    CANCEL_REQUEST("cancel-request", targetsAnotherUser = false),
    ACCEPT_REQUEST("accept-request", targetsAnotherUser = true),
    REFUSE_REQUEST("refuse-request", targetsAnotherUser = true),
    MAKE_ADMIN("make-admin", targetsAnotherUser = true),
    KICK("kick", targetsAnotherUser = true),
    LEAVE("leave", targetsAnotherUser = false),
}
