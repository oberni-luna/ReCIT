package studio.lunabee.exlibris.backend.users

/**
 * The switches `settings` holds, as inventaire.io lists them (`server/models/attributes/user.ts`). Stored and
 * served, and acted on by nothing yet: the notification e-mails are a later task (#62), the contributions'
 * anonymity is read by #77.
 */
object UserSettingNames {
    const val NOTIFICATIONS: String = "notifications"
    private const val CONTRIBUTIONS: String = "contributions"

    private val notifications: List<String> =
        listOf(
            "global",
            "inventories_activity_summary",
            "friend_accepted_request",
            "friendship_request",
            "group_invite",
            "group_acceptRequest",
            "group_join_request",
            "your_item_was_requested",
            "update_on_your_item",
            "update_on_item_you_requested",
        )

    /** Each switch by its path under `settings`: `notifications.global`. */
    val all: Set<String> =
        (notifications.map { "$NOTIFICATIONS.$it" } + "$CONTRIBUTIONS.anonymize").toSet()
}
