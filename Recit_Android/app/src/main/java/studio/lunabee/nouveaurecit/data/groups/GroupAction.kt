package studio.lunabee.nouveaurecit.data.groups

/**
 * `GroupAction`: every membership gesture inventaire.io takes, as the path segment of
 * `PUT /api/groups/<action>` (`server/controllers/groups/groups.ts`).
 */
enum class GroupAction(val path: String) {
    Invite("invite"),
    Accept("accept"),
    Decline("decline"),
    Request("request"),
    CancelRequest("cancel-request"),
    AcceptRequest("accept-request"),
    RefuseRequest("refuse-request"),
    MakeAdmin("make-admin"),
    Kick("kick"),
    Leave("leave"),
    ;

    /**
     * Whether the gesture is about someone else, and so carries a `user` next to the `group` — the
     * server's `groupActionsWithOtherUser`.
     */
    val targetsAnotherUser: Boolean
        get() = when (this) {
            Invite, AcceptRequest, RefuseRequest, MakeAdmin, Kick -> true
            Accept, Decline, Request, CancelRequest, Leave -> false
        }
}
