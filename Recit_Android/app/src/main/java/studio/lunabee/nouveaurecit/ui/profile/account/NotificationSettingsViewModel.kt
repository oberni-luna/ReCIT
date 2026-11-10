package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.user.AccountSettings
import studio.lunabee.nouveaurecit.data.user.NotificationSetting

/**
 * `NotificationSettingsView`'s state (iOS feature 0055): the account's settings as `AccountRepository` holds
 * them, and the writes. Every switch and the frequency are optimistic: the screen redraws from [settings] at
 * once, and a refusal puts the one value back and speaks through the shared snackbar.
 */
class NotificationSettingsViewModel(private val container: AppContainer) : ViewModel() {
    val settings: StateFlow<AccountSettings?> = container.account.settings

    fun setNotification(setting: NotificationSetting, isOn: Boolean) {
        viewModelScope.launch { container.account.setNotification(setting, isOn) }
    }

    fun setSummaryPeriodicity(days: Int) {
        viewModelScope.launch { container.account.setSummaryPeriodicity(days) }
    }

    companion object {
        /** The frequencies the menu offers, in days; 20 is the server's own default. */
        private val PERIODICITIES: List<Int> = listOf(1, 7, 14, AccountSettings.DEFAULT_SUMMARY_PERIODICITY, 30)

        /** The menu's values, plus the account's own when the website set one the menu lacks. */
        fun periodicities(including: Int): List<Int> =
            if (including in PERIODICITIES) PERIODICITIES else (PERIODICITIES + including).sorted()
    }
}
