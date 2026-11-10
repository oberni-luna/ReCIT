package studio.lunabee.nouveaurecit.data.user

import studio.lunabee.nouveaurecit.network.dto.UserDto

/**
 * `AccountSettings` (iOS feature 0055): what only the owner of an account sees of it — the address and
 * whether it is confirmed, the language inventaire.io writes in, the two visibility switches, and the
 * e-mails it sends.
 *
 * Held in memory by [AccountRepository], not in Room: none of it is ever shown for anyone else, and it is
 * read again from `GET /api/user` at every launch. Everything public about the account is on `UserEntity`,
 * where a friend's profile reads it too.
 */
data class AccountSettings(
    val userId: String,
    val email: String?,
    val isEmailValidated: Boolean,
    val language: String?,
    val isFediversable: Boolean,
    val anonymizesContributions: Boolean,
    /** Days between two activity summaries. */
    val summaryPeriodicity: Int = DEFAULT_SUMMARY_PERIODICITY,
    /** Only the keys the account has set: an absent one is on, as [isEnabled] reads it. */
    private val notifications: Map<NotificationSetting, Boolean> = emptyMap(),
) {
    /** An absent switch is read the way the server reads it (`notifications[label] === false`): on. */
    fun isEnabled(setting: NotificationSetting): Boolean = notifications[setting] ?: true

    fun with(setting: NotificationSetting, isEnabled: Boolean): AccountSettings =
        copy(notifications = notifications + (setting to isEnabled))

    /** The general switch off greys every other one: they keep their value, but nothing is sent. */
    fun canEdit(setting: NotificationSetting): Boolean =
        setting == NotificationSetting.Global || isEnabled(NotificationSetting.Global)

    /** The frequency only means something while the summary itself is sent. */
    val canEditSummaryPeriodicity: Boolean
        get() = canEdit(NotificationSetting.InventoriesActivitySummary) && isEnabled(NotificationSetting.InventoriesActivitySummary)

    companion object {
        /** The server's reading of an absent `summaryPeriodicity` (`server/db/couchdb/design_docs/users.ts`). */
        const val DEFAULT_SUMMARY_PERIODICITY: Int = 20

        /**
         * An absent value is read the way the server reads it: contributions are anonymous unless set to
         * `false` (`userShouldBeAnonymized`), the account is off the fediverse until set to `true` (the
         * ActivityPub controllers test `!user.fediversable`), and every e-mail is sent until set to `false`
         * (`check_user_notifications_settings.ts`). A confirmation nobody mentions is not assumed:
         * `validEmail` is always served to the owner. A notification key the app does not know is dropped.
         */
        fun of(dto: UserDto): AccountSettings = AccountSettings(
            userId = dto.id,
            email = dto.email,
            isEmailValidated = dto.validEmail ?: false,
            language = dto.language,
            isFediversable = dto.fediversable ?: false,
            anonymizesContributions = dto.settings?.contributions?.anonymize ?: true,
            summaryPeriodicity = dto.summaryPeriodicity ?: DEFAULT_SUMMARY_PERIODICITY,
            notifications = dto.settings?.notifications.orEmpty()
                .mapNotNull { (key: String, isOn: Boolean) -> NotificationSetting.of(key)?.let { it to isOn } }
                .toMap(),
        )
    }
}
