package studio.lunabee.nouveaurecit.data.user

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
import studio.lunabee.nouveaurecit.network.dto.PasswordChangePayload
import studio.lunabee.nouveaurecit.network.dto.UserDto

/**
 * `UserModel+Account` (iOS feature 0055): « Compte et connexion » and « Notifications par e-mail », the
 * owner's half of the account.
 *
 * The language, the switches and the summary's frequency write themselves, optimistic (ADR 0001): [settings] changes at once, the
 * `PUT /api/user` follows in its [RequestPacer] slot through [profile], and only that one value goes back if
 * the server refuses — two switches flipped in a row are two writes, and the first failing must not undo
 * the second. The address and the password are server first: each has a screen of its own, and a wrong
 * one is something to say there, not to undo.
 *
 * Neither the address nor the password touches the session: the server only sets its cookie at sign-in
 * and sign-up (ADR 0008), so both go through the session client like any other call.
 */
class AccountRepository(
    private val api: ApiService,
    private val profile: ProfileRepository,
    private val runner: OptimisticRunner,
    private val store: MyProfileStore,
) {
    private val _settings: MutableStateFlow<AccountSettings?> = MutableStateFlow(null)

    /** `UserModel.account`: `null` until my user is synced, and again once the account is gone from this phone. */
    val settings: StateFlow<AccountSettings?> = _settings.asStateFlow()

    /** Takes the settings from my user, as `GET /api/user` just served it. */
    fun take(me: UserDto) {
        _settings.value = AccountSettings.of(me)
    }

    /** Sign-out and account deletion: the next account signed in on this phone must not open on these. */
    fun forget() {
        _settings.value = null
    }

    /** Returns the write under way, or `null` when the account already speaks [code]. */
    suspend fun setLanguage(code: String): Job? =
        write(UserAttributeUpdate.of(LANGUAGE, code), code, AccountSettings::language) { copy(language = it) }

    suspend fun setFediversable(isOn: Boolean): Job? =
        write(UserAttributeUpdate.of(FEDIVERSABLE, isOn), isOn, AccountSettings::isFediversable) { copy(isFediversable = it) }

    suspend fun setAnonymizesContributions(isOn: Boolean): Job? =
        write(UserAttributeUpdate.of(ANONYMIZE, isOn), isOn, AccountSettings::anonymizesContributions) { copy(anonymizesContributions = it) }

    /** One e-mail switch, sent as its own `settings.notifications.<key>`. */
    suspend fun setNotification(setting: NotificationSetting, isOn: Boolean): Job? =
        write(UserAttributeUpdate.of(setting.attribute, isOn), isOn, { it.isEnabled(setting) }) { withNotification(setting, it) }

    suspend fun setSummaryPeriodicity(days: Int): Job? =
        write(UserAttributeUpdate.of(SUMMARY_PERIODICITY, days), days, AccountSettings::summaryPeriodicity) { copy(summaryPeriodicity = it) }

    /**
     * Moves the account to a new address, server first. The server mails a confirmation link to it and
     * marks it unconfirmed, which is what the account shows from then on. A refusal throws, and the old
     * address stays.
     */
    suspend fun changeEmail(email: String) {
        profile.updateUserAttribute(UserAttributeUpdate.of(EMAIL, email))
        _settings.update { it?.copy(email = email, isEmailValidated = false) }
        store.updateMyUser { it.copy(email = email) }
    }

    /** `POST /api/auth/email-confirmation`: inventaire.io mails the confirmation link again. */
    suspend fun resendEmailConfirmation() {
        api.sendEmpty<OkStatusDto>(EMAIL_CONFIRMATION_PATH, "POST")
    }

    /** `PUT /api/auth/password`. Throws a [PasswordChangeFailure]. */
    suspend fun changePassword(current: String, new: String) {
        try {
            api.send<PasswordChangePayload, OkStatusDto>(PASSWORD_PATH, method = "PUT", body = PasswordChangePayload(current, new))
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (error: Exception) {
            throw PasswordChangeFailure.of(error)
        }
    }

    /** `writeSetting`: one value, written at once, sent in its slot, and alone to go back if refused. */
    private suspend fun <T> write(
        update: UserAttributeUpdate,
        value: T,
        read: (AccountSettings) -> T,
        assign: AccountSettings.(T) -> AccountSettings,
    ): Job? {
        val current: AccountSettings = _settings.value ?: return null
        val previous: T = read(current)
        // The server answers `400 already up-to-date` to a value it already has.
        if (previous == value) return null
        return runner.run(
            apply = { _settings.update { it?.assign(value) } },
            revert = { _settings.update { it?.assign(previous) } },
            request = { profile.updateUserAttribute(update) },
            stillThere = { _settings.value?.userId == current.userId },
        )
    }

    private companion object {
        const val LANGUAGE: String = "language"
        const val FEDIVERSABLE: String = "fediversable"
        const val ANONYMIZE: String = "settings.contributions.anonymize"
        const val SUMMARY_PERIODICITY: String = "summaryPeriodicity"
        const val EMAIL: String = "email"
        const val EMAIL_CONFIRMATION_PATH: String = "/api/auth/email-confirmation"
        const val PASSWORD_PATH: String = "/api/auth/password"
    }
}
