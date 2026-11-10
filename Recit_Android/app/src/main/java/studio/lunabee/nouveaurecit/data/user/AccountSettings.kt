package studio.lunabee.nouveaurecit.data.user

import studio.lunabee.nouveaurecit.network.dto.UserDto

/**
 * `AccountSettings` (iOS feature 0055): what only the owner of an account sees of it — the address and
 * whether it is confirmed, the language inventaire.io writes in, and the two visibility switches.
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
) {
    companion object {
        /**
         * An absent value is read the way the server reads it: contributions are anonymous unless set to
         * `false` (`userShouldBeAnonymized`), and the account is off the fediverse until set to `true` (the
         * ActivityPub controllers test `!user.fediversable`). A confirmation nobody mentions is not assumed:
         * `validEmail` is always served to the owner.
         */
        fun of(dto: UserDto): AccountSettings = AccountSettings(
            userId = dto.id,
            email = dto.email,
            isEmailValidated = dto.validEmail ?: false,
            language = dto.language,
            isFediversable = dto.fediversable ?: false,
            anonymizesContributions = dto.settings?.contributions?.anonymize ?: true,
        )
    }
}
