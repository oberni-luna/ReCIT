package studio.lunabee.nouveaurecit.data.user

/**
 * `NotificationSetting` (iOS feature 0055): one of the e-mails inventaire.io can send, named by the key it
 * carries under `settings.notifications` — the list `server/models/attributes/user.ts` declares, in the
 * order « Notifications par e-mail » shows them.
 */
enum class NotificationSetting(val key: String) {
    /** Every e-mail below at once. Off, the others stay as they are but none is sent. */
    Global("global"),
    InventoriesActivitySummary("inventories_activity_summary"),
    FriendshipRequest("friendship_request"),
    FriendAcceptedRequest("friend_accepted_request"),
    GroupInvite("group_invite"),
    GroupAcceptRequest("group_acceptRequest"),

    /**
     * Someone asks to join a group I run: the server mails it to the group's admins (`GroupJoinRequest`
     * in `server/lib/emails/email.ts`). An invitation is [GroupInvite].
     */
    GroupJoinRequest("group_join_request"),
    YourItemWasRequested("your_item_was_requested"),
    UpdateOnYourItem("update_on_your_item"),
    UpdateOnItemYouRequested("update_on_item_you_requested");

    /** The `attribute` `PUT /api/user` takes for it. */
    val attribute: String get() = "settings.notifications.$key"

    companion object {
        fun of(key: String): NotificationSetting? = entries.firstOrNull { it.key == key }
    }
}
